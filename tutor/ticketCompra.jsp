<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    Integer idOrden = (Integer) session.getAttribute("ultimaOrden");
    if (idOrden == null) {
        response.sendRedirect(request.getContextPath() + "/tienda.jsp");
        return;
    }

    String correo = request.getUserPrincipal().getName();
    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    PreparedStatement ps = con.prepareStatement(
        "SELECT o.id_orden, o.fecha_compra, o.total, t.nom_tutor " +
        "FROM ordenes o JOIN tutor t ON o.id_tutor = t.id_tutor " +
        "WHERE o.id_orden = ? AND t.correo = ?");
    ps.setInt(1, idOrden);
    ps.setString(2, correo);
    ResultSet rs = ps.executeQuery();

    if (!rs.next()) {
        rs.close(); ps.close(); con.close();
        response.sendRedirect(request.getContextPath() + "/tienda.jsp");
        return;
    }

    String fecha    = rs.getString("fecha_compra");
    double total    = rs.getDouble("total");
    String nomTutor = rs.getString("nom_tutor");
    rs.close(); ps.close();

    ps = con.prepareStatement(
        "SELECT p.nombre, d.cantidad, d.precio_unitario " +
        "FROM detalle_orden d JOIN productos p ON d.id_producto = p.id_producto " +
        "WHERE d.id_orden = ?");
    ps.setInt(1, idOrden);
    rs = ps.executeQuery();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Comprobante – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
    <style>
        @media print {
            .no-print { display: none !important; }
            .topbar    { display: none !important; }
            body { background: white; }
            .card { box-shadow: none; border: 1px solid #ccc; }
        }
    </style>
</head>
<body class="dashboard">

    <div class="topbar no-print">
        <span class="logo">PETIFY</span>
        <a href="${pageContext.request.contextPath}/logout.jsp" class="btn-logout">Cerrar sesión</a>
    </div>

    <div class="main-content">
        <div class="no-print" style="display:flex;gap:1rem;align-items:center;flex-wrap:wrap;margin-bottom:1.5rem;">
            <a href="${pageContext.request.contextPath}/tienda.jsp" class="btn-back" style="margin:0;">
                ← Volver a la tienda
            </a>
            <button onclick="window.print()" class="btn-acceso"
                    style="width:auto;padding:.6rem 1.4rem;cursor:pointer;">
                Descargar / Imprimir
            </button>
        </div>

        <div class="card" style="padding:2rem;max-width:600px;">
            <h2 class="card-title" style="text-align:center;">Comprobante de Compra</h2>
            <p style="text-align:center;color:var(--muted);margin-bottom:1.5rem;">
                Petify &mdash; Orden #<%= idOrden %>
            </p>

            <div style="display:flex;justify-content:space-between;margin-bottom:1.5rem;font-size:.9rem;flex-wrap:wrap;gap:.5rem;">
                <div>
                    <strong>Cliente:</strong> <%= nomTutor %><br>
                    <strong>Correo:</strong> <%= correo %>
                </div>
                <div style="text-align:right;">
                    <strong>Fecha:</strong><br><%= fecha %>
                </div>
            </div>

            <table class="tabla">
                <thead>
                    <tr>
                        <th>Producto</th>
                        <th>Precio u.</th>
                        <th>Cantidad</th>
                        <th>Subtotal</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    while (rs.next()) {
                        String nombre  = rs.getString("nombre");
                        int    cant    = rs.getInt("cantidad");
                        double precioU = rs.getDouble("precio_unitario");
                        double sub     = precioU * cant;
                %>
                    <tr>
                        <td><%= nombre %></td>
                        <td>$<%= String.format("%.2f", precioU) %></td>
                        <td><%= cant %></td>
                        <td>$<%= String.format("%.2f", sub) %></td>
                    </tr>
                <%
                    }
                    rs.close(); ps.close(); con.close();
                %>
                </tbody>
                <tfoot>
                    <tr>
                        <th colspan="3">Total</th>
                        <th>$<%= String.format("%.2f", total) %></th>
                    </tr>
                </tfoot>
            </table>

            <p style="text-align:center;margin-top:2rem;font-size:.85rem;color:var(--muted);">
                Gracias por tu compra. ¡Cuida bien a tu mascota!
            </p>
        </div>
    </div>
</body>
</html>
