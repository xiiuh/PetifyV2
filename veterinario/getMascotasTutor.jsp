<%@ page contentType="application/json;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>

<%
    if(request.getUserPrincipal()==null){
        out.print("[]");
        return;
    }

    String idTutor = request.getParameter("id_tutor");

    if(idTutor==null){
        out.print("[]");
        return;
    }

    try{

        Context ctx = new InitialContext();

        DataSource ds =
                (DataSource) ctx.lookup("java:comp/env/jdbc/petify");

        Connection con = ds.getConnection();

        PreparedStatement ps = con.prepareStatement(
            "SELECT id_mascota,nombre " +
            "FROM mascota " +
            "WHERE id_tutor=? " +
            "ORDER BY nombre"
        );

        ps.setInt(1,Integer.parseInt(idTutor));

        ResultSet rs = ps.executeQuery();

        StringBuilder json = new StringBuilder("[");

        boolean first = true;

        while(rs.next()){

            if(!first){
                json.append(",");
            }

            json.append("{");
            json.append("\"id\":")
                .append(rs.getInt("id_mascota"))
                .append(",");

            json.append("\"nombre\":\"")
                .append(rs.getString("nombre")
                .replace("\"","\\\""))
                .append("\"");

            json.append("}");

            first = false;
        }

        json.append("]");

        rs.close();
        ps.close();
        con.close();

        out.print(json.toString());

    }catch(Exception e){

        out.print("[]");

    }
%>