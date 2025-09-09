# Legacy Inventory Management System

## Overview
This is a legacy J2EE application built with outdated technologies that need modernization.

## Technology Stack (Outdated)
- **Java Version**: 1.6 (EOL since 2013)
- **Application Server**: JBoss 4.2.3 (circa 2008)
- **Framework**: Struts 1.2.9 (deprecated)
- **ORM**: Hibernate 3.6 (outdated)
- **Database**: Oracle 10g
- **Build Tool**: Apache Ant (legacy)
- **Servlet API**: 2.5 (very old)
- **EJB**: 2.1 (obsolete)

## Known Issues (for Konveyor to detect)

### Security Vulnerabilities
- SQL Injection in InventoryServlet.java
- Hardcoded database credentials
- Log4j 1.x with known CVEs
- Basic authentication only
- Unencrypted sensitive data

### Technical Debt
- Direct JDBC calls without connection pooling
- EJB 2.x entity beans (should migrate to JPA)
- System.out.println for logging
- No dependency injection framework
- Monolithic architecture
- No REST APIs (only servlets)
- Oracle-specific database code

### Modernization Targets
- Migrate to Spring Boot 3.x
- Containerize with Docker/Podman
- Move from Oracle to PostgreSQL
- Implement proper logging (SLF4J/Logback)
- Add REST APIs
- Implement microservices architecture
- Add Kubernetes deployment manifests

## Files for Konveyor Analysis
- `pom.xml` - Shows outdated dependencies
- `src/main/java/com/legacy/app/InventoryServlet.java` - SQL injection, direct JDBC
- `src/main/java/com/legacy/app/ProductEJB.java` - EJB 2.x patterns
- `src/main/webapp/WEB-INF/web.xml` - Old servlet configurations
- `src/main/resources/database.properties` - Hardcoded credentials
- `build.xml` - Ant build (should migrate to Maven/Gradle)

## How Konveyor Will Help
1. Analyze dependencies and suggest updates
2. Identify security vulnerabilities
3. Recommend containerization approach
4. Suggest cloud-native patterns
5. Provide migration path from Oracle to PostgreSQL
6. Generate Kubernetes deployment files