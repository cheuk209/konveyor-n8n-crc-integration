package com.legacy.app;

import javax.servlet.*;
import javax.servlet.http.*;
import java.io.*;
import java.sql.*;
import java.util.*;

/**
 * Legacy servlet using outdated patterns
 * - Direct JDBC calls
 * - No connection pooling
 * - SQL injection vulnerabilities
 * - System.out logging
 */
public class InventoryServlet extends HttpServlet {
    
    private static final String DB_URL = "jdbc:oracle:thin:@localhost:1521:XE";
    private static final String DB_USER = "inventory";
    private static final String DB_PASSWORD = "password123";
    
    public void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        System.out.println("Processing inventory request");
        
        String productId = request.getParameter("productId");
        Connection conn = null;
        Statement stmt = null;
        
        try {
            // Legacy: Direct JDBC driver loading
            Class.forName("oracle.jdbc.driver.OracleDriver");
            
            // Legacy: No connection pooling
            conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            stmt = conn.createStatement();
            
            // SECURITY ISSUE: SQL Injection vulnerability
            String sql = "SELECT * FROM products WHERE product_id = '" + productId + "'";
            ResultSet rs = stmt.executeQuery(sql);
            
            response.setContentType("text/html");
            PrintWriter out = response.getWriter();
            out.println("<html><body>");
            out.println("<h1>Inventory Results</h1>");
            
            while (rs.next()) {
                out.println("<p>Product: " + rs.getString("name") + "</p>");
                out.println("<p>Quantity: " + rs.getInt("quantity") + "</p>");
            }
            
            out.println("</body></html>");
            
            rs.close();
            stmt.close();
            conn.close();
            
        } catch (Exception e) {
            // Legacy: Poor error handling
            System.out.println("Error: " + e.getMessage());
            e.printStackTrace();
        } finally {
            try {
                if (stmt != null) stmt.close();
                if (conn != null) conn.close();
            } catch (SQLException se) {
                se.printStackTrace();
            }
        }
    }
    
    public void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}