<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>

<%
    if(request.getUserPrincipal()==null){
        response.sendRedirect(request.getContextPath()+"/login.jsp");
        return;
    }

    String correo = request.getUserPrincipal().getName();

    String idParam = request.getParameter("id");

    if(idParam==null){
        response.sendRedirect("listarCitas.jsp");
        return;
    }

    int idCita = Integer.parseInt(idParam);

    Context ctx = new InitialContext();

    DataSource ds =
            (DataSource) ctx.lookup("java:comp/env/jdbc/petify");

    Connection con = ds.getConnection();

    PreparedStatement ps = con.prepareStatement(
        "SELECT id_vete FROM veterinario WHERE correo=?"
    );

    ps.setString(1,correo);

    ResultSet rs = ps.executeQuery();

    int idVete = 0;

    if(rs.next()){
        idVete = rs.getInt("id_vete");
    }

    rs.close();
    ps.close();

    ps = con.prepareStatement(
        "DELETE FROM citas " +
        "WHERE id_citas=? " +
        "AND id_vete=?"
    );

    ps.setInt(1,idCita);
    ps.setInt(2,idVete);

    ps.executeUpdate();

    ps.close();
    con.close();

    response.sendRedirect("listarCitas.jsp");
%>