package com.legacy.app;

import javax.ejb.*;
import java.rmi.RemoteException;
import java.sql.*;
import java.util.*;

/**
 * Legacy EJB 2.x Entity Bean
 * Outdated patterns that Konveyor will flag:
 * - EJB 2.x is obsolete
 * - Remote interfaces add unnecessary complexity
 * - Container-managed persistence is outdated
 */
public class ProductEJB implements EntityBean {
    
    private EntityContext context;
    private String productId;
    private String productName;
    private int quantity;
    private double price;
    
    // Legacy: EJB 2.x lifecycle methods
    public void setEntityContext(EntityContext ctx) throws EJBException {
        this.context = ctx;
    }
    
    public void unsetEntityContext() throws EJBException {
        this.context = null;
    }
    
    public String ejbCreate(String id, String name, int qty, double price) 
            throws CreateException {
        this.productId = id;
        this.productName = name;
        this.quantity = qty;
        this.price = price;
        
        // Legacy: Direct database access in EJB
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = getConnection();
            String sql = "INSERT INTO products VALUES (?, ?, ?, ?)";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, productId);
            pstmt.setString(2, productName);
            pstmt.setInt(3, quantity);
            pstmt.setDouble(4, price);
            pstmt.executeUpdate();
        } catch (SQLException e) {
            throw new CreateException("Failed to create product: " + e.getMessage());
        } finally {
            closeConnection(conn, pstmt);
        }
        
        return productId;
    }
    
    public void ejbPostCreate(String id, String name, int qty, double price) {
        // Post-creation logic
    }
    
    public void ejbActivate() throws EJBException {
        // Activation logic
    }
    
    public void ejbPassivate() throws EJBException {
        // Passivation logic
    }
    
    public void ejbLoad() throws EJBException {
        // Load from database
    }
    
    public void ejbStore() throws EJBException {
        // Store to database
    }
    
    public void ejbRemove() throws RemoveException, EJBException {
        // Remove from database
    }
    
    // Legacy: JNDI lookup for database
    private Connection getConnection() throws SQLException {
        try {
            InitialContext ic = new InitialContext();
            DataSource ds = (DataSource) ic.lookup("java:comp/env/jdbc/OracleDS");
            return ds.getConnection();
        } catch (Exception e) {
            throw new SQLException("Cannot get connection: " + e.getMessage());
        }
    }
    
    private void closeConnection(Connection conn, Statement stmt) {
        try {
            if (stmt != null) stmt.close();
            if (conn != null) conn.close();
        } catch (SQLException e) {
            // Ignore
        }
    }
    
    // Business methods
    public String getProductId() {
        return productId;
    }
    
    public String getProductName() {
        return productName;
    }
    
    public void setProductName(String name) {
        this.productName = name;
    }
    
    public int getQuantity() {
        return quantity;
    }
    
    public void setQuantity(int qty) {
        this.quantity = qty;
    }
}