using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using WebTIendaElectronica.Models;

namespace WebTIendaElectronica.Controllers
{
    [Authorize]
    public class VentasController : Controller
    {
        private readonly TiendaElectronicaFinalContext _context;

        public VentasController(TiendaElectronicaFinalContext context)
        {
            _context = context;
        }

        // GET: Ventas
        public async Task<IActionResult> Index()
        {
            var ventas = await _context.Venta
                                       .Include(v => v.IdClienteNavigation)
                                       .Include(v => v.IdEmpleadoNavigation)
                                       .Include(v => v.IdProductoNavigation)
                                       .Where(v => v.Estado != -1)
                                       .ToListAsync();

            return View(ventas);
        }

        // GET: Ventas/Details/5
        public async Task<IActionResult> Details(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var ventum = await _context.Venta
                .Include(v => v.IdClienteNavigation)
                .Include(v => v.IdEmpleadoNavigation)
                .Include(v => v.IdProductoNavigation)
                .FirstOrDefaultAsync(m => m.Id == id && m.Estado != -1);

            if (ventum == null)
            {
                return NotFound();
            }

            return View(ventum);
        }

        // GET: Ventas/Create
        public IActionResult Create()
        {
            ViewData["IdCliente"] = new SelectList(_context.Clientes.Where(c => c.Estado != -1), "Id", "NombreCompleto");
            ViewData["IdEmpleado"] = new SelectList(_context.Empleados.Where(e => e.Estado != -1), "Id", "NombreCompleto");

            // *** FIX HERE: Set ViewBag.ProductosList ***
            ViewBag.ProductosList = new SelectList(_context.Productos.Where(p => p.Estado != -1), "Id", "Descripcion");

            return View();
        }

        // POST: Ventas/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create([Bind("Id,IdCliente,IdEmpleado,Transaccion,Fecha,Total,IdProducto")] Ventum ventum)
        {
            if (ModelState.IsValid)
            {
                ventum.UsuarioRegistro = User.Identity.Name ?? "System";
                ventum.FechaRegistro = DateTime.Now;
                ventum.Estado = 1;

                _context.Add(ventum);
                await _context.SaveChangesAsync();
                return RedirectToAction(nameof(Index));
            }

            // *** FIX HERE: Repopulate ViewBag.ProductosList on validation failure ***
            ViewData["IdCliente"] = new SelectList(_context.Clientes.Where(c => c.Estado != -1), "Id", "NombreCompleto", ventum.IdCliente);
            ViewData["IdEmpleado"] = new SelectList(_context.Empleados.Where(e => e.Estado != -1), "Id", "NombreCompleto", ventum.IdEmpleado);
            ViewBag.ProductosList = new SelectList(_context.Productos.Where(p => p.Estado != -1), "Id", "Descripcion", ventum.IdProducto);

            return View(ventum);
        }

        // GET: Ventas/Edit/5
        public async Task<IActionResult> Edit(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            // Fetch the Ventum along with its navigation properties for display in the form
            var ventum = await _context.Venta
                                       .Include(v => v.IdClienteNavigation)
                                       .Include(v => v.IdEmpleadoNavigation)
                                       .Include(v => v.IdProductoNavigation)
                                       .FirstOrDefaultAsync(m => m.Id == id && m.Estado != -1); // Assuming Estado != -1 means active

            if (ventum == null)
            {
                return NotFound();
            }

            // Populate SelectLists for dropdowns
            ViewData["IdCliente"] = new SelectList(_context.Clientes.Where(c => c.Estado != -1), "Id", "NombreCompleto", ventum.IdCliente);
            ViewData["IdEmpleado"] = new SelectList(_context.Empleados.Where(e => e.Estado != -1), "Id", "Nombres", ventum.IdEmpleado); // Assuming Empleado.Nombres is for display
            ViewBag.ProductosList = new SelectList(_context.Productos.Where(p => p.Estado != -1), "Id", "Descripcion", ventum.IdProducto);

            return View(ventum);
        }

        // POST: Ventas/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        // [Bind] attribute lists ONLY the fields that are sent from the form for editing.
        // This prevents overposting vulnerabilities.
        public async Task<IActionResult> Edit(int id, [Bind("Id,IdCliente,IdEmpleado,Transaccion,Fecha,Total,IdProducto")] Ventum ventum)
        {
            if (id != ventum.Id)
            {
                return NotFound();
            }

            if (ModelState.IsValid)
            {
                try
                {
                    // Fetch the original entity from the database to preserve values
                    // for fields that are not included in the form (e.g., UsuarioRegistro, FechaRegistro, Estado).
                    var originalVentum = await _context.Venta
                                                     .AsNoTracking() // Use AsNoTracking to avoid conflicts with the 'ventum' object
                                                     .FirstOrDefaultAsync(v => v.Id == id);

                    if (originalVentum == null)
                    {
                        // This might happen if the record was deleted by another process between GET and POST.
                        return NotFound();
                    }

                    // Manually assign values from the original entity for fields not bound from the form
                    ventum.UsuarioRegistro = originalVentum.UsuarioRegistro;
                    ventum.FechaRegistro = originalVentum.FechaRegistro;
                    ventum.Estado = originalVentum.Estado; // Preserve the original Estado value

                    _context.Update(ventum); // Attach and mark the entity as modified
                    await _context.SaveChangesAsync();
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!VentumExists(ventum.Id))
                    {
                        return NotFound();
                    }
                    else
                    {
                        throw; // Re-throw the exception if it's not a 'not found' concurrency issue
                    }
                }
                return RedirectToAction(nameof(Index));
            }

            // If ModelState is not valid, re-populate SelectLists and return the view with validation errors
            ViewData["IdCliente"] = new SelectList(_context.Clientes.Where(c => c.Estado != -1), "Id", "NombreCompleto", ventum.IdCliente);
            ViewData["IdEmpleado"] = new SelectList(_context.Empleados.Where(e => e.Estado != -1), "Id", "Nombres", ventum.IdEmpleado);
            ViewBag.ProductosList = new SelectList(_context.Productos.Where(p => p.Estado != -1), "Id", "Descripcion", ventum.IdProducto);

            return View(ventum);
        }

        // GET: Ventas/Delete/5
        public async Task<IActionResult> Delete(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var ventum = await _context.Venta
                .Include(v => v.IdClienteNavigation)
                .Include(v => v.IdEmpleadoNavigation)
                .Include(v => v.IdProductoNavigation)
                .FirstOrDefaultAsync(m => m.Id == id && m.Estado != -1);

            if (ventum == null)
            {
                return NotFound();
            }

            return View(ventum);
        }

        // POST: Ventas/Delete/5
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            var ventum = await _context.Venta.FindAsync(id);
            if (ventum != null)
            {
                ventum.Estado = -1;
                _context.Update(ventum);
            }

            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }

        // NEW ACTION: To fetch all active product data (ID, Saldo, PrecioVenta, Description) for client-side use
        [HttpGet]
        public async Task<IActionResult> GetAllProductsData()
        {
            var products = await _context.Productos
                                         .Where(p => p.Estado != -1) // Only active products
                                         .Select(p => new {
                                             id = p.Id,
                                             saldo = p.Saldo,
                                             precioVenta = p.PrecioVenta,
                                             descripcion = p.Descripcion // Include description if needed for display logic
                                         })
                                         .ToListAsync();
            return Json(products);
        }

        // NEW ACTION: To render a print-friendly view of a sale
        [HttpGet]
        public async Task<IActionResult> PrintDetails(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var ventum = await _context.Venta
                .Include(v => v.IdClienteNavigation)
                .Include(v => v.IdEmpleadoNavigation)
                .Include(v => v.IdProductoNavigation) // Include if you only have one product per sale
                                                      // If you have VentaDetalle for multiple products, you would include that here:
                                                      // .Include(v => v.VentaDetalles) // Assuming a collection property named VentaDetalles
                                                      //    .ThenInclude(vd => vd.IdProductoNavigation) // And then include the product details for each detail item
                .FirstOrDefaultAsync(m => m.Id == id && m.Estado != -1);

            if (ventum == null)
            {
                return NotFound();
            }

            // Return the Ventum model to a specific print-friendly view
            return View("~/Views/Ventas/PrintDetails.cshtml", ventum);
        }

        private bool VentumExists(int id)
        {
            return _context.Venta.Any(e => e.Id == id && e.Estado != -1);
        }
    }
}