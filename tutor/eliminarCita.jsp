<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String correo = request.getUserPrincipal().getName();
    String idParam = request.getParameter("id");
    if (idParam == null) { response.sendRedirect("listarCitas.jsp"); return; }
    int idCita = Integer.parseInt(idParam);

    Context ctx = new javax.naming.InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    PreparedStatement ps = con.prepareStatement("SELECT id_tutor FROM tutor WHERE correo = ?");
    ps.setString(1, correo);
    ResultSet rs = ps.executeQuery();
    int idTutor = 0;
    if (rs.next()) idTutor = rs.getInt("id_tutor");
    rs.close(); ps.close();

    ps = con.prepareStatement("DELETE FROM citas WHERE id_citas = ? AND id_tutor = ?");
    ps.setInt(1, idCita);
    ps.setInt(2, idTutor);
    ps.executeUpdate();
    ps.close(); con.close();

    response.sendRedirect("listarCitas.jsp");
%>