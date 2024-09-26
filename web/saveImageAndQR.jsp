<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.text.DateFormat"%>
<%@page import="java.util.Date"%>
<%@page import="java.sql.SQLException"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="QRAttendance.SQLconnection"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.Statement"%>
<%@page import="java.sql.Connection"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.Base64" %>

<%
    String qrValue = request.getParameter("qrValue");
    String imageData = request.getParameter("imageData");

   

    // Convert Data URL to byte array and set as BLOB parameter
    Connection con = SQLconnection.getconnection();
    Statement st = con.createStatement();
    Statement st1 = con.createStatement();
    Statement st2 = con.createStatement();
    try {

        ResultSet rs = st.executeQuery("SELECT * FROM students where  unique_id='" + qrValue + "' AND ustatus='Active'");
        if (rs.next()) {

            String name = rs.getString("name");
            String dept = rs.getString("sdept");
            session.setAttribute("sname", name);
            DateFormat formatter = new SimpleDateFormat("dd/MM/yyyy");

            Date today = new Date();

            Date todayWithZeroTime = formatter.parse(formatter.format(today));

            String attendanceStatus = "present";
            String uid = rs.getString("id");

            boolean isPresent = "present".equals(attendanceStatus);
            Date date = todayWithZeroTime;

            try {
                Connection connection = SQLconnection.getconnection();

                // Check if attendance for the same date and employee already exists
                String checkQuery = "SELECT COUNT(*) AS count FROM attendance WHERE date = ? AND uid = ?";
                try (PreparedStatement checkStatement = connection.prepareStatement(checkQuery)) {
                    java.sql.Date sqlDate = new java.sql.Date(date.getTime());
                    checkStatement.setDate(1, sqlDate);
                    checkStatement.setString(2, uid);

                    try (ResultSet resultSet = checkStatement.executeQuery()) {
                        if (resultSet.next() && resultSet.getInt("count") > 0) {
                            // Attendance record already exists, handle accordingly
                            response.sendRedirect("Students.jsp?Already");
                            return; // Exit the JSP page
                        }
                    }
                }

                // Insert the attendance record if not already exists
                String insertQuery = "INSERT INTO attendance (date, is_present, uid, sname, sdept, upic) VALUES (?, ?, ?,?,?,?)";
                try (PreparedStatement preparedStatement = connection.prepareStatement(insertQuery)) {
                    java.sql.Date sqlDate = new java.sql.Date(date.getTime());
                    preparedStatement.setDate(1, sqlDate);
                    preparedStatement.setBoolean(2, isPresent);
                    preparedStatement.setString(3, uid);
                    preparedStatement.setString(4, name);
                    preparedStatement.setString(5, dept);
                    byte[] imageBytes = Base64.getDecoder().decode(imageData.split(",")[1]);
                    preparedStatement.setBytes(6, imageBytes);
                    preparedStatement.executeUpdate();

                    response.sendRedirect("Students.jsp?LogAdded");
                }
            } catch (SQLException e) {
                e.printStackTrace();
                response.getWriter().println("An error occurred while recording attendance.");
            }
%>

<%
        } else {
            response.sendRedirect("Students.jsp?LogFailed");

        }
        rs.close();
        con.close();
    } catch (Exception ex) {
        ex.printStackTrace();
    }
%>
%>
