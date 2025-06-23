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
    public class ProductosController : Controller
    {
        private readonly TiendaElectronicaFinalContext _context;

        public ProductosController(TiendaElectronicaFinalContext context)
        {
            _context = context;
        }

        // GET: Productos
        // Displays all products that are NOT logically deleted (Estado != -1)
        public async Task<IActionResult> Index()
        {
            var productos = _context.Productos
                .Include(p => p.IdCategoriaNavigation) // Eagerly load Category data
                .Include(p => p.IdMarcaNavigation)     // Eagerly load Brand data
                .Where(x => x.Estado != -1)            // Filter for logically active products
                .OrderBy(x => x.Descripcion);          // Order by Description for better readability

            return View(await productos.ToListAsync());
        }

        // GET: Productos/Details/5
        // Displays details of a specific product, including logically deleted ones if accessed directly by ID.
        public async Task<IActionResult> Details(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var producto = await _context.Productos
                .Include(p => p.IdCategoriaNavigation) // Eagerly load Category data for display
                .Include(p => p.IdMarcaNavigation)     // Eagerly load Brand data for display
                .FirstOrDefaultAsync(m => m.Id == id); // Get a single product by ID
            if (producto == null)
            {
                return NotFound();
            }

            return View(producto);
        }

        // GET: Productos/Create
        // Prepares the form for creating a new product.
        public IActionResult Create()
        {
            // Populate dropdowns using "Id" as the value and "Descripcion" as the displayed text
            ViewData["IdCategoria"] = new SelectList(_context.Categoria, "Id", "Descripcion"); // Assuming Categoria has a 'Descripcion' property
            ViewData["IdMarca"] = new SelectList(_context.Marcas, "Id", "Descripcion");
            ViewData["IdProducto"]=new SelectList(_context.Productos, "Id", "Descripcion");                   // Assuming Marca has a 'Descripcion' property
            return View();
        }

        // POST: Productos/Create
        // Handles the submission of the new product form, setting metadata.
        [HttpPost]
        [ValidateAntiForgeryToken]
        // The [Bind] attribute is maintained as per your original code.
        // We will override UsuarioRegistro, FechaRegistro, and Estado after binding.
        public async Task<IActionResult> Create([Bind("Id,IdCategoria,IdMarca,Codigo,Descripcion,Saldo,PrecioVenta")] Producto producto)
        {
            // ModelState.IsValid checks based on data annotations (e.g., [Required]) on your model.
            // If you have specific custom validation (like the previous example's string.IsNullOrEmpty checks),
            // you might add them here as well.
            if (ModelState.IsValid)
            {
                // Set metadata properties server-side
                producto.UsuarioRegistro = User.Identity.Name ?? "System"; // Use authenticated user or "System" fallback
                producto.FechaRegistro = DateTime.Now;
                producto.Estado = 1; // Set default state to active (1) for new products

                _context.Add(producto);
                await _context.SaveChangesAsync();
                return RedirectToAction(nameof(Index));
            }
            // If ModelState is not valid, repopulate dropdowns and return to view
            ViewData["IdCategoria"] = new SelectList(_context.Categoria, "Id", "Descripcion", producto.IdCategoria);
            ViewData["IdMarca"] = new SelectList(_context.Marcas, "Id", "Descripcion", producto.IdMarca);
            return View(producto);
        }

        // GET: Productos/Edit/5
        // Retrieves a product for editing. Includes related data if your Edit view displays it.
        public async Task<IActionResult> Edit(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            // Fetch the product, including navigation properties if your edit view displays their descriptions
            var producto = await _context.Productos
                .Include(p => p.IdCategoriaNavigation) // Include for displaying category description
                .Include(p => p.IdMarcaNavigation)     // Include for displaying brand description
                .FirstOrDefaultAsync(m => m.Id == id);

            if (producto == null)
            {
                return NotFound();
            }
            // Populate dropdowns with Description for display, and Id for value
            ViewData["IdCategoria"] = new SelectList(_context.Categoria, "Id", "Descripcion", producto.IdCategoria);
            ViewData["IdMarca"] = new SelectList(_context.Marcas, "Id", "Descripcion", producto.IdMarca);
            return View(producto);
        }

        // POST: Productos/Edit/5
        // Handles the submission of the edited product form, updating metadata.
        [HttpPost]
        [ValidateAntiForgeryToken]
        // Keep [Bind] for properties allowed to be updated from the form.
        // UsuarioRegistro will be updated here. FechaRegistro will be preserved.
        public async Task<IActionResult> Edit(int id, [Bind("Id,IdCategoria,IdMarca,Codigo,Descripcion,Saldo,PrecioVenta,Estado")] Producto producto)
        {
            if (id != producto.Id)
            {
                return NotFound();
            }

            if (ModelState.IsValid)
            {
                try
                {
                    // To preserve FechaRegistro and update UsuarioRegistro,
                    // we fetch the original entity's FechaRegistro.
                    // AsNoTracking() is used to avoid tracking conflicts since 'producto' is also attached.
                    var originalProducto = await _context.Productos
                                                        .AsNoTracking()
                                                        .FirstOrDefaultAsync(p => p.Id == id);

                    if (originalProducto == null)
                    {
                        return NotFound(); // Product no longer exists, concurrency issue or direct access
                    }

                    // Preserve original FechaRegistro
                    producto.FechaRegistro = originalProducto.FechaRegistro;
                    // Update UsuarioRegistro to the current user (last modifier)
                    producto.UsuarioRegistro = User.Identity.Name ?? "System";

                    _context.Update(producto); // Mark the entity as modified
                    await _context.SaveChangesAsync();
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!ProductoExists(producto.Id))
                    {
                        return NotFound();
                    }
                    else
                    {
                        throw; // Re-throw for other concurrency issues
                    }
                }
                return RedirectToAction(nameof(Index));
            }
            // If ModelState is not valid, repopulate dropdowns and return to view
            ViewData["IdCategoria"] = new SelectList(_context.Categoria, "Id", "Descripcion", producto.IdCategoria);
            ViewData["IdMarca"] = new SelectList(_context.Marcas, "Id", "Descripcion", producto.IdMarca);
            return View(producto);
        }

        // GET: Productos/Delete/5
        // Displays the confirmation page for logical deletion.
        public async Task<IActionResult> Delete(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var producto = await _context.Productos
                .Include(p => p.IdCategoriaNavigation) // Eagerly load Category for display
                .Include(p => p.IdMarcaNavigation)     // Eagerly load Brand for display
                .FirstOrDefaultAsync(m => m.Id == id);
            if (producto == null)
            {
                return NotFound();
            }

            return View(producto);
        }

        // POST: Productos/Delete/5
        // Performs the logical deletion by setting Estado to -1.
        [HttpPost, ActionName("Delete")] // Match the GET action name
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            var producto = await _context.Productos.FindAsync(id); // Find the product by ID

            if (producto == null)
            {
                return NotFound(); // Product not found, should not happen if Delete GET was correct
            }

            // Perform logical deletion: set Estado to -1
            producto.Estado = -1;
            // Update UsuarioRegistro to record who logically deleted it
            producto.UsuarioRegistro = User.Identity.Name ?? "System";
            // You might also want to add a 'FechaBaja' or 'FechaEliminacion' property to record WHEN it was deleted.

            _context.Update(producto); // Mark the entity as modified
            await _context.SaveChangesAsync(); // Save the changes to the database
            return RedirectToAction(nameof(Index)); // Redirect to the list view
        }

        // Helper method to check if a product exists.
        // This currently checks for existence by ID regardless of Estado.
        // If you need to check for *active* existence, modify this.
        private bool ProductoExists(int id)
        {
            return _context.Productos.Any(e => e.Id == id);
        }
    }
}