<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String correo = request.getUserPrincipal().getName();
    String idParam = request.getParameter("id");

    if (idParam == null) {
        response.sendRedirect(request.getContextPath() + "/tutor/listarMascotas.jsp");
        return;
    }

    int idMascota = Integer.parseInt(idParam);

    try {
        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();

        PreparedStatement psCheck = con.prepareStatement(
            "SELECT m.id_mascota FROM mascota m " +
            "JOIN tutor t ON m.id_tutor = t.id_tutor " +
            "WHERE m.id_mascota = ? AND t.correo = ?");
        psCheck.setInt(1, idMascota);
        psCheck.setString(2, correo);
        ResultSet rs = psCheck.executeQuery();

        if (rs.next()) {
            rs.close(); psCheck.close();
            PreparedStatement psDel = con.prepareStatement(
                "DELETE FROM mascota WHERE id_mascota = ?");
            psDel.setInt(1, idMascota);
            psDel.executeUpdate();
            psDel.close();
        } else {
            rs.close(); psCheck.close();
        }

        con.close();
    } catch (Exception e) {
    }

    response.sendRedirect(request.getContextPath() + "/tutor/listarMascotas.jsp");
%>