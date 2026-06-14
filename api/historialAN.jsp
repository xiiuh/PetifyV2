<%@ page contentType="application/json;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    response.setCharacterEncoding("UTF-8");
    response.setHeader("Access-Control-Allow-Origin", "*");
    response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    response.setHeader("Access-Control-Allow-Headers", "Content-Type");

    if ("OPTIONS".equals(request.getMethod())) { response.setStatus(200); return; }

    String idMascotaStr = request.getParameter("id_mascota");
    if (idMascotaStr == null || idMascotaStr.isEmpty()) {
        out.print("{\"success\":false,\"mensaje\":\"Falta id_mascota\"}");
        return;
    }

    try {
        int idMascota = Integer.parseInt(idMascotaStr);

        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();

        PreparedStatement ps = con.prepareStatement(
            "SELECT c.id_consulta, c.motivo, c.motivo_otro, c.peso, c.diagnostico, " +
            "       c.tratamiento, c.medicamentos, c.observaciones, " +
            "       ci.fecha AS fecha_consulta, v.nom_vete " +
            "FROM consultas c " +
            "LEFT JOIN citas ci ON c.id_cita = ci.id_citas " +
            "LEFT JOIN veterinario v ON c.id_vete = v.id_vete " +
            "WHERE c.id_mascota = ? ORDER BY c.id_consulta DESC");
        ps.setInt(1, idMascota);
        ResultSet rs = ps.executeQuery();

        StringBuilder sb = new StringBuilder("{\"success\":true,\"historial\":[");
        boolean first = true;
        while (rs.next()) {
            if (!first) sb.append(",");
            first = false;
            String motivo    = rs.getString("motivo");
            String motivoOtro = rs.getString("motivo_otro");
            String diag      = rs.getString("diagnostico");
            String trat      = rs.getString("tratamiento");
            String meds      = rs.getString("medicamentos");
            String obs       = rs.getString("observaciones");
            String fecha     = rs.getString("fecha_consulta");
            String vete      = rs.getString("nom_vete");

            sb.append("{")
              .append("\"id_consulta\":").append(rs.getInt("id_consulta")).append(",")
              .append("\"fecha_consulta\":\"").append(fecha  != null ? fecha  : "").append("\",")
              .append("\"motivo\":\"").append(motivo != null ? motivo.replace("\"","\\\"") : "").append("\",")
              .append("\"motivo_otro\":\"").append(motivoOtro != null ? motivoOtro.replace("\"","\\\"") : "").append("\",")
              .append("\"peso\":").append(rs.getObject("peso") != null ? rs.getDouble("peso") : 0).append(",")
              .append("\"diagnostico\":\"").append(diag != null ? diag.replace("\"","\\\"") : "").append("\",")
              .append("\"tratamiento\":\"").append(trat != null ? trat.replace("\"","\\\"") : "").append("\",")
              .append("\"medicamentos\":\"").append(meds != null ? meds.replace("\"","\\\"") : "").append("\",")
              .append("\"observaciones\":\"").append(obs  != null ? obs.replace("\"","\\\"")  : "").append("\",")
              .append("\"veterinario\":\"").append(vete  != null ? vete.replace("\"","\\\"")  : "").append("\",")
              .append("\"id_mascota\":").append(idMascota)
              .append("}");
        }
        sb.append("]}");
        rs.close(); ps.close(); con.close();
        out.print(sb.toString());

    } catch (NumberFormatException e) {
        out.print("{\"success\":false,\"mensaje\":\"id_mascota inválido\"}");
    } catch (Exception e) {
        out.print("{\"success\":false,\"mensaje\":\"Error interno\"}");
    }
%>
