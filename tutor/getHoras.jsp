<%@ page contentType="application/json;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    String fecha   = request.getParameter("fecha");
    String idVete  = request.getParameter("id_vete");

    Context ctx = new javax.naming.InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    PreparedStatement ps = con.prepareStatement(
        "SELECT hora FROM citas WHERE fecha = ? AND id_vete = ?"
    );
    ps.setString(1, fecha);
    ps.setInt(2, Integer.parseInt(idVete));
    ResultSet rs = ps.executeQuery();

    StringBuilder json = new StringBuilder("[");
    boolean first = true;
    while (rs.next()) {
        if (!first) json.append(",");
        json.append("\"").append(rs.getString("hora")).append("\"");
        first = false;
    }
    json.append("]");

    rs.close(); ps.close(); con.close();
    out.print(json.toString());
%>