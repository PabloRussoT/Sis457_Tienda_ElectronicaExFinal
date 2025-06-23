using System;
using System.Collections.Generic;

namespace WebTIendaElectronica.Models;

public partial class Producto
{
    public int Id { get; set; }

    public int IdCategoria { get; set; }

    public int IdMarca { get; set; }

    public string Codigo { get; set; } = null!;

    public string Descripcion { get; set; } = null!;

    public decimal Saldo { get; set; }

    public decimal PrecioVenta { get; set; }

    public string UsuarioRegistro { get; set; } = null!;

    public DateTime FechaRegistro { get; set; }

    public short Estado { get; set; }

    public virtual Categorium IdCategoriaNavigation { get; set; } = null!;

    public virtual Marca IdMarcaNavigation { get; set; } = null!;

    public virtual ICollection<Ventum> Venta { get; set; } = new List<Ventum>();

    public virtual ICollection<VentaDetalle> VentaDetalles { get; set; } = new List<VentaDetalle>();
}
