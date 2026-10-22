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
