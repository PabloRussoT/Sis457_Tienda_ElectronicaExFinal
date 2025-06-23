using System;
using System.Collections.Generic;

namespace WebTIendaElectronica.Models;

public partial class Cliente
{
    public int Id { get; set; }

    public string NombreCompleto { get; set; }

    public string? Nit { get; set; }

    public string? Direccion { get; set; }

    public string? Telefono { get; set; }

    public string? Email { get; set; }

    public string UsuarioRegistro { get; set; } = null!;

    public DateTime FechaRegistro { get; set; }

    public short Estado { get; set; }

    public virtual ICollection<Ventum> Venta { get; set; } = new List<Ventum>();

}
