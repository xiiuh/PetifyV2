<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String ok = request.getParameter("ok");

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    PreparedStatement ps = con.prepareStatement(
        "SELECT o.id_orden, o.fecha_compra, o.total, o.metodo_pago, " +
        "       t.nom_tutor, t.correo, t.telefono " +
        "FROM ordenes o JOIN tutor t ON o.id_tutor = t.id_tutor " +
        "WHERE o.estado = 'pendiente' " +
        "ORDER BY o.fecha_compra ASC");
    ResultSet rs = ps.executeQuery();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ventas Pendientes – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
    <style>
        .badge-pendiente {
            background:#fff8e1;color:#f57f17;
            font-size:.75rem;font-weight:600;
            padding:.2rem .65rem;border-radius:20px;
        }
        .productos-lista { font-size:.85rem; color:var(--muted); margin:.4rem 0 0; }
        .btn-confirmar {
            background:#2e7d32;color:#fff;border:none;
            padding:.5rem 1.1rem;border-radius:8px;cursor:pointer;
            font-family:inherit;font-size:.88rem;font-weight:600;
        }
        .btn-confirmar:hover { background:#1b5e20; }
        details > summary { cursor:pointer; font-size:.85rem; color:var(--muted); }
        details[open] > summary { margin-bottom:.4rem; }
    </style>
</head>
<body class="dashboard">
    <div class="topbar">
        <span class="logo">PETIFY</span>
        <a href="${pageContext.request.contextPath}/logout.jsp" class="btn-logout">Cerrar sesión</a>
    </div>

    <div class="main-content">
        <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:1rem;margin-bottom:1.5rem;">
            <div>
                <a href="${pageContext.request.contextPath}/veterinario/agenda.jsp" class="btn-back" style="margin:0 0 .5rem;">← Volver</a>
                <h2 class="page__title" style="margin:.5rem 0 0;">Ventas Pendientes</h2>
            </div>
            <a href="${pageContext.request.contextPath}/veterinario/historialVentas.jsp"
               class="btn-acceso" style="display:inline-block;width:auto;padding:.6rem 1.4rem;text-decoration:none;">
                Ver historial completo
            </a>
        </div>

        <% if ("1".equals(ok)) { %>
            <p style="color:#2e7d32;font-weight:600;margin-bottom:1rem;">Orden confirmada correctamente.</p>
        <% } %>

        <div class="card" style="padding:1.5rem;overflow-x:auto;">
        <%
            boolean hay = false;
            while (rs.next()) {
                hay = true;
                int    idOrden   = rs.getInt("id_orden");
                String fecha     = rs.getString("fecha_compra");
                double total     = rs.getDouble("total");
                String metodo    = rs.getString("metodo_pago");
                String nomTutor  = rs.getString("nom_tutor");
                String correoT   = rs.getString("correo");
                String telefonoT = rs.getString("telefono");

                PreparedStatement psDet = con.prepareStatement(
                    "SELECT p.nombre, d.cantidad, d.precio_unitario " +
                    "FROM detalle_orden d JOIN productos p ON d.id_producto = p.id_producto " +
                    "WHERE d.id_orden = ?");
                psDet.setInt(1, idOrden);
                ResultSet rsDet = psDet.executeQuery();
        %>
            <div class="card" style="margin-bottom:1.2rem;padding:1.2rem;border:1px solid #e0e0e0;">
                <div style="display:flex;justify-content:space-between;align-items:flex-start;flex-wrap:wrap;gap:.8rem;">
                    <div>
                        <span style="font-weight:700;font-size:1rem;">Orden #<%= idOrden %></span>
                        <span class="badge-pendiente" style="margin-left:.6rem;">Pendiente</span>
                        <div style="margin-top:.4rem;font-size:.88rem;color:var(--muted);">
                            <%= fecha %>
                            &nbsp;&mdash;&nbsp;
                            Método: <strong><%= "tarjeta".equals(metodo) ? "Tarjeta" : "Efectivo" %></strong>
                        </div>
                        <div style="margin-top:.5rem;font-size:.92rem;">
                            <strong><%= nomTutor %></strong>
                            &nbsp;|&nbsp; <%= correoT %>
                            &nbsp;|&nbsp; <%= telefonoT %>
                        </div>
                        <details style="margin-top:.6rem;">
                            <summary>Ver productos</summary>
                            <table class="tabla" style="margin-top:.4rem;min-width:320px;">
                                <thead>
                                    <tr><th>Producto</th><th>Cant.</th><th>Precio u.</th><th>Subtotal</th></tr>
                                </thead>
                                <tbody>
                                <%
                                    while (rsDet.next()) {
                                        String nomProd  = rsDet.getString("nombre");
                                        int    cantProd = rsDet.getInt("cantidad");
                                        double precioU  = rsDet.getDouble("precio_unitario");
                                %>
                                    <tr>
                                        <td><%= nomProd %></td>
                                        <td><%= cantProd %></td>
                                        <td>$<%= String.format("%.2f", precioU) %></td>
                                        <td>$<%= String.format("%.2f", precioU * cantProd) %></td>
                                    </tr>
                                <% } %>
                                </tbody>
                                <tfoot>
                                    <tr><th colspan="3">Total</th><th>$<%= String.format("%.2f", total) %></th></tr>
                                </tfoot>
                            </table>
                        </details>
                    </div>
                    <form method="post" action="${pageContext.request.contextPath}/veterinario/confirmarOrden.jsp"
                          style="display:flex;align-items:center;">
                        <input type="hidden" name="id_orden" value="<%= idOrden %>">
                        <button type="submit" class="btn-confirmar">Confirmar recogida</button>
                    </form>
                </div>
            </div>
        <%
                rsDet.close(); psDet.close();
            }
            rs.close(); ps.close(); con.close();

            if (!hay) {
        %>
            <p style="text-align:center;color:var(--muted);padding:2rem;">
                No hay ventas pendientes en este momento.
            </p>
        <% } %>
        </div>
    </div>
</body>
</html>
