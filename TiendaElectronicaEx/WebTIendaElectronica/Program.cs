using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.StaticFiles; // <--- ADD THIS USING DIRECTIVE
using Microsoft.EntityFrameworkCore;
using WebTIendaElectronica.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();
builder.Services.AddDbContext<TiendaElectronicaFinalContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options => options.LoginPath = new PathString("/Account/Login"));

builder.Services.AddMemoryCache();
builder.Services.AddSession();
builder.Services.AddRazorPages();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseCookiePolicy();
app.UseSession();
app.UseAuthentication();

app.UseHttpsRedirection();
app.UseRouting();

// THIS IS THE CORRECT WAY TO SERVE STATIC FILES
app.UseStaticFiles(); // <--- REPLACE app.MapStaticAssets(); WITH THIS LINE

app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");
// REMOVE .WithStaticAssets(); from here, it's not needed or standard.


app.Run();