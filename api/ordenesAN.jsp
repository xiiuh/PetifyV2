<%@ page contentType="application/json;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    response.setCharacterEncoding("UTF-8");
    response.setHeader("Access-Control-Allow-Origin", "*");
    response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    response.setHeader("Access-Control-Allow-Headers", "Content-Type");

    if ("OPTIONS".equals(request.getMethod())) { response.setStatus(200); return; }
%>
<%@ include file="_checkToken.jsp" %>
<%
    String idTutorStr = request.getParameter("id_tutor");
    if (idTutorStr == null || idTutorStr.isEmpty()) {
        out.print("{\"success\":false,\"mensaje\":\"Falta id_tutor\"}");
        return;
    }

    try {
        int idTutor = Integer.parseInt(idTutorStr);

        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();

        PreparedStatement ps = con.prepareStatement(
            "SELECT id_orden, fecha_compra, total, metodo_pago, estado " +
            "FROM ordenes WHERE id_tutor=? ORDER BY fecha_compra DESC");
        ps.setInt(1, idTutor);
        ResultSet rs = ps.executeQuery();

        PreparedStatement psDet = con.prepareStatement(
            "SELECT d.id_producto, p.nombre, d.cantidad, d.precio_unitario " +
            "FROM detalle_orden d JOIN productos p ON d.id_producto = p.id_producto " +
            "WHERE d.id_orden=?");

        StringBuilder sb = new StringBuilder("{\"success\":true,\"ordenes\":[");
        boolean firstOrden = true;
        while (rs.next()) {
            if (!firstOrden) sb.append(",");
            firstOrden = false;
            int    idOrden    = rs.getInt("id_orden");
            String fecha      = rs.getString("fecha_compra");
            double total      = rs.getDouble("total");
            String metodo     = rs.getString("metodo_pago");
            String estado     = rs.getString("estado");

            sb.append("{")
              .append("\"id_orden\":").append(idOrden).append(",")
              .append("\"fecha_compra\":\"").append(fecha).append("\",")
              .append("\"total\":").append(total).append(",")
              .append("\"metodo_pago\":\"").append(metodo).append("\",")
              .append("\"estado\":\"").append(estado).append("\",")
              .append("\"detalle\":[");

            psDet.setInt(1, idOrden);
            ResultSet rsDet = psDet.executeQuery();
            boolean firstDet = true;
            while (rsDet.next()) {
                if (!firstDet) sb.append(",");
                firstDet = false;
                sb.append("{")
                  .append("\"id_producto\":").append(rsDet.getInt("id_producto")).append(",")
                  .append("\"nombre\":\"").append(rsDet.getString("nombre").replace("\"","\\\"")).append("\",")
                  .append("\"cantidad\":").append(rsDet.getInt("cantidad")).append(",")
                  .append("\"precio_unitario\":").append(rsDet.getDouble("precio_unitario"))
                  .append("}");
            }
            rsDet.close();
            sb.append("]}");
        }
        sb.append("]}");
        rs.close(); ps.close(); psDet.close(); con.close();
        out.print(sb.toString());

    } catch (NumberFormatException e) {
        out.print("{\"success\":false,\"mensaje\":\"id_tutor inválido\"}");
    } catch (Exception e) {
        out.print("{\"success\":false,\"mensaje\":\"Error interno\"}");
    }
%>
