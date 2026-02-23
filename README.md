
# 📚 Database Systems Feb2026 – Course Repository

Welcome to the official repository for the **Databases After Graduation** course.

This repository contains all course materials, backend examples, SQL scripts, assignments, and installation guides required throughout the course.

---

## 🎯 Course Overview

This course focuses on practical, production-level database skills used in real backend systems.

Topics include:

- Relational data modeling
- Advanced SQL querying
- Indexing & performance optimization
- Execution plans
- Connecting databases to backend APIs
- ORM vs Raw SQL trade-offs
- Connection pooling
- Backend best practices

By the end of this course, you will understand not only how to write SQL queries, but how databases behave inside real-world backend architectures.

---

## 📂 Repository Structure
```
Class_1_Data_Modeling_for_Real_World_Systems/
│── Concepts/
│   │── Entities_Relationships_Schema_Design
│   │── Query_Driven_Data_Modeling
│   │── Normalization_vs_Denormalization
│   │── Read_vs_Write_Heavy_Schema_Design
│── Tools/
│   │── MySQL

Class_2_Production_SQL_and_Query_Execution/
│── Concepts/
│   │── Production_Level_SQL
│   │── Query_Execution_Behavior
│   │── Execution_Plans_EXPLAIN
│   │── Indexing_Strategies
│   │── Read_vs_Write_Performance_Tradeoffs
│── Tools/
│   │── MySQL
│   │── SQL_Execution_Plan_Analysis

Class_3_Databases_Behind_APIs/
│── Concepts/
│   │── Backend_Database_Architecture
│   │── API_Request_Lifecycle
│   │── Database_Access_Patterns
│   │── Connection_Pooling
│   │── Pagination_Offset_and_Cursor
│   │── ORM_vs_Raw_SQL_Tradeoffs
│── Tools/
│   │── Python_FastAPI
│   │── ORM
│   │── Postman
│   │── Swagger_OpenAPI

Class_4_Concurrency_Consistency_and_Reliability/
│── Concepts/
│   │── Transactions
│   │── Commit_and_Rollback
│   │── Race_Conditions
│   │── Concurrent_Request_Handling
│   │── Transaction_Isolation_Levels
│   │── Read_Replicas_and_Consistency_Tradeoffs
```
---

## ⚙️ Installation Requirements

Before starting, make sure you have:

### Required Tools
- MySQL
- Python 3.10+
- Postman
- VS Code (recommended)

### Required Python Libraries

```bash
pip install fastapi
pip install uvicorn
pip install sqlalchemy
pip install pymysql
pip install cryptography
pip install pydantic python-dotenv
```

## 🧠 Learning Philosophy
This course emphasizes:

- Understanding how databases behave in backend systems
- Writing efficient, scalable SQL
- Designing clean relational schemas
- Thinking in terms of data architecture, not just tables
- The goal is to bridge the gap between academic SQL knowledge and production-level backend development.