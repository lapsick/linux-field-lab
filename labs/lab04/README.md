# Лабораторна 04 · Третя мережа

Виконуйте команди з кореня репозиторію у Bash на Linux із підтримкою
netns/veth та доступом до sudo. Змінюються лише власні fl-a, fl-r, fl-b,
fl-c; host default route і firewall не змінюються.

## Схема та маршрути

```text
A (fl-a)                     R (fl-r)                    B (fl-b)
fa 10.77.1.2/24 ───── fr0 10.77.1.1/24
                         fr1 10.77.2.1/24 ───── fb 10.77.2.2/24
                         frc 10.77.3.1/24
                                │
                         fc0 10.77.3.2/24
                             C (fl-c)
```

A і B потребують маршрутів до 10.77.3.0/24 через локальні адреси R.
C потребує маршрутів до обох мереж A та B. Відповідь C→A йде через
10.77.3.1, потім R пересилає її через fr0. На R ядро створює три
безпосередньо підключені маршрути після призначення адрес і підняття
інтерфейсів; окремий gateway на R не потрібний. Кінцеві вузли також
отримують від ядра маршрут до своєї локальної /24.

## База A–R–B для відновлення та дня 10

Спершу перегляньте `ip netns list`. Якщо власна база вже існує й A→B
працює, пропустіть цей блок. Якщо імена зайняті невідомими просторами,
не змінюйте їх. Для нової бази всі три імена та fa/fr0/fb/fr1 мають бути вільні.

```bash
sudo ip netns add fl-probe
sudo ip netns del fl-probe
ip netns list

sudo ip netns add fl-a
sudo ip netns add fl-r
sudo ip netns add fl-b
sudo ip link add fa type veth peer name fr0
sudo ip link set fa netns fl-a
sudo ip link set fr0 netns fl-r
sudo ip link add fb type veth peer name fr1
sudo ip link set fb netns fl-b
sudo ip link set fr1 netns fl-r
sudo ip -n fl-a addr add 10.77.1.2/24 dev fa
sudo ip -n fl-r addr add 10.77.1.1/24 dev fr0
sudo ip -n fl-r addr add 10.77.2.1/24 dev fr1
sudo ip -n fl-b addr add 10.77.2.2/24 dev fb
sudo ip -n fl-a link set lo up
sudo ip -n fl-r link set lo up
sudo ip -n fl-b link set lo up
sudo ip -n fl-a link set fa up
sudo ip -n fl-r link set fr0 up
sudo ip -n fl-r link set fr1 up
sudo ip -n fl-b link set fb up
sudo ip -n fl-a route add 10.77.2.0/24 via 10.77.1.1
sudo ip -n fl-b route add 10.77.1.0/24 via 10.77.2.1
sudo ip netns exec fl-r sysctl -w net.ipv4.ip_forward=1
sudo ip netns exec fl-a ping -n -c 4 -W 2 10.77.2.2
echo $?
```

Продовжуйте лише після успішного ping (код 0). Виконуйте команди по черзі;
при помилці зупиніться та перевірте частково створену схему.

## Розширення

Перевірте, що fl-c, fc0 та frc вільні, а forwarding у fl-r дорівнює 1:

```bash
ip netns list
ip link show
sudo ip -n fl-r link show
sudo ip netns exec fl-r sysctl net.ipv4.ip_forward

sudo ip netns add fl-c
sudo ip link add fc0 type veth peer name frc
sudo ip link set fc0 netns fl-c
sudo ip link set frc netns fl-r
sudo ip -n fl-c addr add 10.77.3.2/24 dev fc0
sudo ip -n fl-r addr add 10.77.3.1/24 dev frc
sudo ip -n fl-c link set lo up
sudo ip -n fl-c link set fc0 up
sudo ip -n fl-r link set frc up
sudo ip -n fl-a route add 10.77.3.0/24 via 10.77.1.1
sudo ip -n fl-b route add 10.77.3.0/24 via 10.77.2.1
sudo ip -n fl-c route add 10.77.1.0/24 via 10.77.3.1
sudo ip -n fl-c route add 10.77.2.0/24 via 10.77.3.1
```

## Перевірки та збереження доказів

Функція записує команду, вивід і фактичний код завершення. Використовуйте
новий файл журналу для кожного проходу. Очікуваний невдалий ping не перериває
наступні перевірки. Помилки запису журналу потрібно усунути перед продовженням.

```bash
mkdir -p -- evidence/lab04
log="evidence/lab04/run-$(date +%Y%m%d-%H%M%S)-$$.txt"
record() {
  local status
  {
    printf '\n$'
    printf ' %q' "$@"
    printf '\n'
    if "$@"; then
      status=0
    else
      status=$?
    fi
    printf 'exit=%s\n' "$status"
  } 2>&1 | tee -a -- "$log"
}
record sudo ip -n fl-a -br addr
record sudo ip -n fl-b -br addr
record sudo ip -n fl-c -br addr
record sudo ip -n fl-r -br addr
record sudo ip -n fl-r route show
record sudo ip -n fl-c route show
record sudo ip -n fl-a route get 10.77.2.2
record sudo ip netns exec fl-a ping -n -c 4 -W 2 10.77.2.2
record sudo ip -n fl-a route get 10.77.3.2
record sudo ip netns exec fl-a ping -n -c 4 -W 2 10.77.3.2
record sudo ip -n fl-b route get 10.77.3.2
record sudo ip netns exec fl-b ping -n -c 4 -W 2 10.77.3.2
```

Прогноз перед відмовою: A→C втратить зв'язок, A→B залишиться справним.
Маршрут у A до C залишається вибраним навіть при недоступному кінцевому
інтерфейсі: успішний `route get` сам по собі не доводить доставку.

```bash
record sudo ip -n fl-c link set fc0 down
record sudo ip -n fl-c -br link
record sudo ip -n fl-a route get 10.77.3.2
record sudo ip netns exec fl-a ping -n -c 4 -W 2 10.77.3.2
record sudo ip -n fl-a route get 10.77.2.2
record sudo ip netns exec fl-a ping -n -c 4 -W 2 10.77.2.2
record sudo ip -n fl-c link set fc0 up
record sudo ip -n fl-a route get 10.77.3.2
record sudo ip netns exec fl-a ping -n -c 4 -W 2 10.77.3.2
record sudo ip -n fl-a route get 10.77.2.2
record sudo ip netns exec fl-a ping -n -c 4 -W 2 10.77.2.2
```

Таблиця нижче — прогноз, а не результати запуску. Заповніть фактичні коди
й втрати пакетів із журналу.

| Пара | Вибраний шлях | C up | fc0 down | fc0 знову up |
|---|---|---|---|---|
| A→B | via 10.77.1.1 dev fa | очікується 0 | очікується 0 | очікується 0 |
| A→C | via 10.77.1.1 dev fa | очікується 0 | очікується ненульовий код | очікується 0 |
| B→C | via 10.77.2.1 dev fb | очікується 0 | не перевіряється | не перевіряється |

## Окремий rollback до A–R–B

Спершу виконайте `sudo ip netns pids fl-c`. Якщо є процеси, перевірте кожен
через `ps -p PID -o pid,user,comm,args`, завершіть лише відомі власні процеси
командою `sudo kill -TERM PID` та дочекайтеся порожнього списку PID.
Не видаляйте namespace із невідомими процесами.

```bash
record sudo ip -n fl-a route del 10.77.3.0/24 via 10.77.1.1
record sudo ip -n fl-b route del 10.77.3.0/24 via 10.77.2.1
record sudo ip netns del fl-c
sudo ip -n fl-r link show
# Видалення fl-c зазвичай уже видалило обидва кінці veth.
# Тільки якщо попередній список ще містить frc:
# sudo ip -n fl-r link del frc
record sudo ip -n fl-r -br addr
record sudo ip -n fl-a route show
record sudo ip -n fl-b route show
record sudo ip -n fl-a route get 10.77.2.2
record sudo ip netns exec fl-a ping -n -c 4 -W 2 10.77.2.2
```

Після rollback очікується код ping 0 без перебудови бази. Маршрути C
зникають разом із namespace, підключений маршрут R до 10.77.3.0/24 — разом
із frc. Адреси та маршрути бази зберігаються.

## Завершення

Лише після перевірки rollback перегляньте процеси:

```bash
sudo ip netns pids fl-a
sudo ip netns pids fl-r
sudo ip netns pids fl-b
```

Для кожного PID застосуйте ту саму перевірку власності та завершення, що
для fl-c. Коли списки порожні, видаліть лише свої простори:

```bash
sudo ip netns del fl-a
sudo ip netns del fl-r
sudo ip netns del fl-b
ip netns list
```

Команди відновлення бази вище залишаються для дня 10. Перед комітом
перегляньте журнал на сторонні PID, імена вузлів та мережеві дані.
