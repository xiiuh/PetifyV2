<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%! private static String esc(String s) { if(s==null)return""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#x27;"); } %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String correo = request.getUserPrincipal().getName();

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    PreparedStatement ps = con.prepareStatement(
        "SELECT o.id_orden, o.fecha_compra, o.total, o.metodo_pago, o.estado " +
        "FROM ordenes o JOIN tutor t ON o.id_tutor = t.id_tutor " +
        "WHERE t.correo = ? " +
        "ORDER BY o.fecha_compra DESC");
    ps.setString(1, correo);
    ResultSet rs = ps.executeQuery();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mis Órdenes – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
    <style>
        .badge {
            font-size:.75rem;font-weight:600;
            padding:.2rem .65rem;border-radius:20px;display:inline-block;
        }
        .badge-pendiente  { background:#fff8e1;color:#f57f17; }
        .badge-confirmada { background:#e8f5e9;color:#2e7d32; }
        .badge-cancelada  { background:#fce4ec;color:#c62828; }
        details > summary { cursor:pointer; font-size:.85rem; color:var(--muted); }
        details[open] > summary { margin-bottom:.4rem; }
    </style>
</head>
<body class="dashboard">
    <jsp:include page="/nav.jsp"/>

    <div class="main-content">
        <div style="margin-bottom:1.5rem;">
            <a href="${pageContext.request.contextPath}/tutor/dashboard.jsp" class="btn-back" style="margin:0 0 .5rem;">← Volver al panel</a>
            <h2 class="page__title" style="margin:.5rem 0 0;">Mis Órdenes</h2>
        </div>

        <div class="card" style="padding:1.5rem;overflow-x:auto;">
            <table class="tabla">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Fecha</th>
                        <th>Total</th>
                        <th>Método de pago</th>
                        <th>Estado</th>
                        <th>Productos</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    boolean hay = false;
                    while (rs.next()) {
                        hay = true;
                        int    idOrden = rs.getInt("id_orden");
                        String fecha   = rs.getString("fecha_compra");
                        double total   = rs.getDouble("total");
                        String metodo  = rs.getString("metodo_pago");
                        String estado  = rs.getString("estado");

                        String badgeClass = "pendiente".equals(estado) ? "badge-pendiente"
                                          : "confirmada".equals(estado) ? "badge-confirmada"
                                          : "badge-cancelada";
                        String estadoLabel = "pendiente".equals(estado) ? "Pendiente — esperando recogida"
                                           : "confirmada".equals(estado) ? "Recogida confirmada"
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
                    <td style="font-size:.85rem;"><%= fecha %></td>
                    <td><strong>$<%= String.format("%.2f", total) %></strong></td>
                    <td><%= "tarjeta".equals(metodo) ? "Tarjeta" : "Efectivo" %></td>
                    <td><span class="badge <%= badgeClass %>"><%= estadoLabel %></span></td>
                    <td>
                        <details>
                            <summary>Ver detalle</summary>
                            <table class="tabla" style="margin-top:.4rem;min-width:280px;">
                                <thead><tr><th>Producto</th><th>Cant.</th><th>Precio u.</th><th>Subtotal</th></tr></thead>
                                <tbody>
                                <%
                                    while (rsDet.next()) {
                                        double pu = rsDet.getDouble("precio_unitario");
                                        int    c  = rsDet.getInt("cantidad");
                                %>
                                    <tr>
                                        <td><%= esc(rsDet.getString("nombre")) %></td>
                                        <td><%= c %></td>
                                        <td>$<%= String.format("%.2f", pu) %></td>
                                        <td>$<%= String.format("%.2f", pu * c) %></td>
                                    </tr>
                                <% } %>
                                </tbody>
                                <tfoot>
                                    <tr><th colspan="3">Total</th><th>$<%= String.format("%.2f", total) %></th></tr>
                                </tfoot>
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
                    <td colspan="6" style="text-align:center;color:var(--muted);padding:2rem;">
                        Aún no tienes órdenes registradas.
                        <a href="${pageContext.request.contextPath}/tienda.jsp" style="display:block;margin-top:.5rem;">Ir a la tienda</a>
                    </td>
                </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
