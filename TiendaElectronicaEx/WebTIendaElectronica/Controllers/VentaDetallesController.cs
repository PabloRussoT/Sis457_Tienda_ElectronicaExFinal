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
    public class VentaDetallesController : Controller
    {
        private readonly TiendaElectronicaFinalContext _context;

        public VentaDetallesController(TiendaElectronicaFinalContext context)
        {
            _context = context;
        }

        // GET: VentaDetalles
        public async Task<IActionResult> Index()
        {
            // Include related entities for display and filter by Estado for logical deletion
            var tiendaElectronicaFinalContext = _context.VentaDetalles
                .Include(v => v.IdProductoNavigation)    // Include Product details
                .Include(v => v.IdVentaNavigation)       // Include Venta header details
                                                         // If VentaDetalle has an Estado property for logical deletion
                .Where(v => v.Estado != -1); // Filter for active details

            return View(await tiendaElectronicaFinalContext.ToListAsync());
        }

        // GET: VentaDetalles/Details/5
        public async Task<IActionResult> Details(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var ventaDetalle = await _context.VentaDetalles
                .Include(v => v.IdProductoNavigation)
                .Include(v => v.IdVentaNavigation)
                .FirstOrDefaultAsync(m => m.Id == id);
            if (ventaDetalle == null)
            {
                return NotFound();
            }

            return View(ventaDetalle);
        }

        // GET: VentaDetalles/Create
        public IActionResult Create()
        {
            // Populate dropdowns with descriptive text
            ViewData["IdProducto"] = new SelectList(_context.Productos.Where(p => p.Estado != -1), "Id", "Descripcion"); // Only active products
            ViewData["IdVenta"] = new SelectList(_context.Venta.Where(v => v.Estado != -1), "Id", "Transaccion"); // Assuming "Transaccion" is a good display for Venta
            return View();
        }

        // POST: VentaDetalles/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create([Bind("Id,IdVenta,IdProducto,Cantidad,PrecioUnitario,Total")] VentaDetalle ventaDetalle)
        {
            if (ModelState.IsValid)
            {
                // Set audit fields server-side
                ventaDetalle.UsuarioRegistro = User.Identity.Name ?? "System";
                ventaDetalle.FechaRegistro = DateTime.Now;
                ventaDetalle.Estado = 1; // Set default state to active for a new detail

                _context.Add(ventaDetalle);
                await _context.SaveChangesAsync();
                return RedirectToAction(nameof(Index));
            }
            // Repopulate ViewDatas if validation fails
            ViewData["IdProducto"] = new SelectList(_context.Productos.Where(p => p.Estado != -1), "Id", "Descripcion", ventaDetalle.IdProducto);
            ViewData["IdVenta"] = new SelectList(_context.Venta.Where(v => v.Estado != -1), "Id", "Transaccion", ventaDetalle.IdVenta);
            return View(ventaDetalle);
        }

        // GET: VentaDetalles/Edit/5
        public async Task<IActionResult> Edit(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var ventaDetalle = await _context.VentaDetalles.FindAsync(id);
            if (ventaDetalle == null)
            {
                return NotFound();
            }
            // Populate dropdowns with descriptive text, selecting the current value
            ViewData["IdProducto"] = new SelectList(_context.Productos.Where(p => p.Estado != -1), "Id", "Descripcion", ventaDetalle.IdProducto);
            ViewData["IdVenta"] = new SelectList(_context.Venta.Where(v => v.Estado != -1), "Id", "Transaccion", ventaDetalle.IdVenta);
            return View(ventaDetalle);
        }

        // POST: VentaDetalles/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, [Bind("Id,IdVenta,IdProducto,Cantidad,PrecioUnitario,Total,Estado")] VentaDetalle ventaDetalle)
        {
            if (id != ventaDetalle.Id)
            {
                return NotFound();
            }

            if (ModelState.IsValid)
            {
                try
                {
                    // Fetch original entity to preserve FechaRegistro
                    var originalVentaDetalle = await _context.VentaDetalles
                                                             .AsNoTracking()
                                                             .FirstOrDefaultAsync(vd => vd.Id == id);

                    if (originalVentaDetalle == null)
                    {
                        return NotFound();
                    }

                    ventaDetalle.FechaRegistro = originalVentaDetalle.FechaRegistro; // Preserve original creation date
                    ventaDetalle.UsuarioRegistro = User.Identity.Name ?? "System";  // Update user who last modified

                    _context.Update(ventaDetalle);
                    await _context.SaveChangesAsync();
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!VentaDetalleExists(ventaDetalle.Id))
                    {
                        return NotFound();
                    }
                    else
                    {
                        throw;
                    }
                }
                return RedirectToAction(nameof(Index));
            }
            // Repopulate ViewDatas if validation fails
            ViewData["IdProducto"] = new SelectList(_context.Productos.Where(p => p.Estado != -1), "Id", "Descripcion", ventaDetalle.IdProducto);
            ViewData["IdVenta"] = new SelectList(_context.Venta.Where(v => v.Estado != -1), "Id", "Transaccion", ventaDetalle.IdVenta);
            return View(ventaDetalle);
        }

        // GET: VentaDetalles/Delete/5
        public async Task<IActionResult> Delete(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var ventaDetalle = await _context.VentaDetalles
                .Include(v => v.IdProductoNavigation)
                .Include(v => v.IdVentaNavigation)
                .FirstOrDefaultAsync(m => m.Id == id);
            if (ventaDetalle == null)
            {
                return NotFound();
            }

            return View(ventaDetalle);
        }

        // POST: VentaDetalles/Delete/5
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            var ventaDetalle = await _context.VentaDetalles.FindAsync(id);
            if (ventaDetalle != null)
            {
                // Perform logical deletion: set Estado to -1
                ventaDetalle.Estado = -1;
                ventaDetalle.UsuarioRegistro = User.Identity.Name ?? "System"; // Update who logically deleted
                // _context.VentaDetalles.Remove(ventaDetalle); // Commented out physical deletion
                _context.Update(ventaDetalle); // Mark as updated for logical deletion
            }

            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }

        private bool VentaDetalleExists(int id)
        {
            return _context.VentaDetalles.Any(e => e.Id == id);
        }
    }
}