using System;
using System.Collections.Generic;

namespace WebTIendaElectronica.Models;

public partial class Ventum
{
    public int Id { get; set; }

    public int IdCliente { get; set; }

    public int IdEmpleado { get; set; }

    public string Transaccion { get; set; } = null!;

    public DateOnly Fecha { get; set; }

    public decimal Total { get; set; }

    public string UsuarioRegistro { get; set; } = null!;

    public DateTime FechaRegistro { get; set; }

    public short Estado { get; set; }

    public int? IdProducto { get; set; }

    public virtual Cliente IdClienteNavigation { get; set; } = null!;

    public virtual Empleado IdEmpleadoNavigation { get; set; } = null!;

    public virtual Producto? IdProductoNavigation { get; set; }

    public virtual ICollection<VentaDetalle> VentaDetalles { get; set; } = new List<VentaDetalle>();
}
