var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.MapGet("/", () => Results.Text("field-lab\n", "text/plain"));

app.Run("http://127.0.0.1:8080");
