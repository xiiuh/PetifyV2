<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect(request.getContextPath() + "/veterinario/ventasPendientes.jsp");
        return;
    }

    String idOrdenStr = request.getParameter("id_orden");
    if (idOrdenStr == null || idOrdenStr.isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/veterinario/ventasPendientes.jsp");
        return;
    }

    try {
        int idOrden = Integer.parseInt(idOrdenStr);
        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();

        PreparedStatement ps = con.prepareStatement(
            "UPDATE ordenes SET estado = 'confirmada' WHERE id_orden = ? AND estado = 'pendiente'");
        ps.setInt(1, idOrden);
        ps.executeUpdate();
        ps.close();
        con.close();
    } catch (Exception e) {
        // Si falla, redirigir igual
    }

    response.sendRedirect(request.getContextPath() + "/veterinario/ventasPendientes.jsp?ok=1");
%>
