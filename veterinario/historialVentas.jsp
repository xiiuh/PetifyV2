<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String filtroEstado = request.getParameter("estado");
    if (filtroEstado == null) filtroEstado = "todas";

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    String sql = "SELECT o.id_orden, o.fecha_compra, o.total, o.metodo_pago, o.estado, " +
                 "       t.nom_tutor, t.correo " +
                 "FROM ordenes o JOIN tutor t ON o.id_tutor = t.id_tutor ";
    if (!"todas".equals(filtroEstado)) {
        sql += "WHERE o.estado = ? ";
    }
    sql += "ORDER BY o.fecha_compra DESC";

    PreparedStatement ps = con.prepareStatement(sql);
    if (!"todas".equals(filtroEstado)) {
        ps.setString(1, filtroEstado);
    }
    ResultSet rs = ps.executeQuery();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Historial de Ventas – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
    <style>
        .badge {
            font-size:.75rem;font-weight:600;
            padding:.2rem .65rem;border-radius:20px;display:inline-block;
        }
        .badge-pendiente   { background:#fff8e1;color:#f57f17; }
        .badge-confirmada  { background:#e8f5e9;color:#2e7d32; }
        .badge-cancelada   { background:#fce4ec;color:#c62828; }
        .filter-bar { display:flex;gap:.5rem;flex-wrap:wrap;margin-bottom:1.2rem; }
        .filter-btn {
            padding:.4rem 1rem;border-radius:20px;border:1.5px solid #ddd;
            background:#fff;font-family:inherit;font-size:.85rem;cursor:pointer;font-weight:500;
        }
        .filter-btn.active { border-color:var(--accent,#6b4ff6);color:var(--accent,#6b4ff6);background:#f3f0ff; }
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
                <h2 class="page__title" style="margin:.5rem 0 0;">Historial de Ventas</h2>
            </div>
            <a href="${pageContext.request.contextPath}/veterinario/ventasPendientes.jsp"
               class="btn-acceso" style="display:inline-block;width:auto;padding:.6rem 1.4rem;text-decoration:none;">
                Ver pendientes
            </a>
        </div>

        <div class="filter-bar">
            <a href="?estado=todas"     class="filter-btn <%= "todas".equals(filtroEstado)      ? "active" : "" %>">Todas</a>
            <a href="?estado=pendiente" class="filter-btn <%= "pendiente".equals(filtroEstado)  ? "active" : "" %>">Pendientes</a>
            <a href="?estado=confirmada"class="filter-btn <%= "confirmada".equals(filtroEstado) ? "active" : "" %>">Confirmadas</a>
            <a href="?estado=cancelada" class="filter-btn <%= "cancelada".equals(filtroEstado)  ? "active" : "" %>">Canceladas</a>
        </div>

        <div class="card" style="padding:1.5rem;overflow-x:auto;">
            <table class="tabla">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Cliente</th>
                        <th>Fecha</th>
                        <th>Total</th>
                        <th>Método</th>
                        <th>Estado</th>
                        <th>Productos</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    boolean hay = false;
                    while (rs.next()) {
                        hay = true;
                        int    idOrden  = rs.getInt("id_orden");
                        String fecha    = rs.getString("fecha_compra");
                        double total    = rs.getDouble("total");
                        String metodo   = rs.getString("metodo_pago");
                        String estado   = rs.getString("estado");
                        String nomTutor = rs.getString("nom_tutor");
                        String correoT  = rs.getString("correo");

                        String badgeClass = "pendiente".equals(estado) ? "badge-pendiente"
                                          : "confirmada".equals(estado) ? "badge-confirmada"
                                          : "badge-cancelada";
                        String estadoLabel = "pendiente".equals(estado) ? "Pendiente"
                                           : "confirmada".equals(estado) ? "Confirmada"
                                           : "Cancelada";

                        PreparedStatement psDet = con.prepareStatement(
                            "SELECT p.nombre, d.cantidad, d.precio_unitario " +
                            "FROM detalle_orden d JOIN productos p ON d.id_producto = p.id_producto " +
                            "WHERE d.id_orden = ?");
                        psDet.setInt(1, idOrden);
                        ResultSet rsDet = psDet.executeQuery();
                %>
                <tr>
                    <td><strong>#<%= idOrden %></strong></td>
                    <td>
                        <strong><%= nomTutor %></strong><br>
                        <span style="font-size:.8rem;color:var(--muted);"><%= correoT %></span>
                    </td>
                    <td style="font-size:.85rem;"><%= fecha %></td>
                    <td><strong>$<%= String.format("%.2f", total) %></strong></td>
                    <td><%= "tarjeta".equals(metodo) ? "Tarjeta" : "Efectivo" %></td>
                    <td><span class="badge <%= badgeClass %>"><%= estadoLabel %></span></td>
                    <td>
                        <details>
                            <summary>Ver detalle</summary>
                            <table class="tabla" style="margin-top:.4rem;min-width:280px;">
                                <thead><tr><th>Producto</th><th>Cant.</th><th>Precio u.</th></tr></thead>
                                <tbody>
                                <%
                                    while (rsDet.next()) {
                                %>
                                    <tr>
                                        <td><%= rsDet.getString("nombre") %></td>
                                        <td><%= rsDet.getInt("cantidad") %></td>
                                        <td>$<%= String.format("%.2f", rsDet.getDouble("precio_unitario")) %></td>
                                    </tr>
                                <% } %>
                                </tbody>
                            </table>
                        </details>
                    </td>
                </tr>
                <%
                        rsDet.close(); psDet.close();
                    }
                    rs.close(); ps.close(); con.close();

                    if (!hay) {
                %>
                <tr>
                    <td colspan="7" style="text-align:center;color:var(--muted);padding:2rem;">
                        No hay ventas registradas.
                    </td>
                </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
