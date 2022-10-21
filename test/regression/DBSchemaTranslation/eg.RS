CREATE TABLE CONSULTANT (
    Fname CHARACTER (20) NOT NULL,
    Lname CHARACTER (20) NOT NULL,
    Address CHARACTER (40))
PRIMARY KEY (Fname, Lname)

CREATE TABLE EMPLOYEE (
    SIN INTEGER NOT NULL,
    Fname CHARACTER (20),
    Lname CHARACTER (20),
    Address CHARACTER (40),
    department_Number INTEGER NOT NULL,
    supervisor_SIN INTEGER)
PRIMARY KEY (SIN)
FOREIGN KEY (department_Number)
    REFERENCES DEPARTMENT
    --* RELATIONSHIP : works_for
    --* ROLES : employee (1, 1), department (1, n)
FOREIGN KEY (supervisor_SIN)
    REFERENCES EMPLOYEE
    --* RELATIONSHIP : supervision
    --* ROLES : supervisee (0, 1), supervisor (0, n)

CREATE TABLE DEPARTMENT (
    Number INTEGER NOT NULL,
    Name CHARACTER (40) NOT NULL,
    manager_SIN INTEGER NOT NULL,
    manages_StartDate CHARACTER (8))
UNIQUE (Name)
PRIMARY KEY (Number)
FOREIGN KEY (manager_SIN)
    REFERENCES EMPLOYEE
    --* RELATIONSHIP : manages
    --* ROLES : department_managed (1, 1), manager (0, 1)

CREATE TABLE PROJECT (
    Name CHARACTER (40) NOT NULL,
    controlling_dept_Number INTEGER NOT NULL)
PRIMARY KEY (Name)
FOREIGN KEY (controlling_dept_Number)
    REFERENCES DEPARTMENT
    --* RELATIONSHIP : controls
    --* ROLES : controlled_proj (1, 1), controlling_dept (0, n)

CREATE TABLE SUPPLIER (
    Name CHARACTER (40) NOT NULL)
PRIMARY KEY (Name)

CREATE TABLE PART (
    Number INTEGER NOT NULL)
PRIMARY KEY (Number)

CREATE TABLE DEPENDENT (
    Relationship CHARACTER (40),
    Name CHARACTER (40) NOT NULL,
    employee_SIN INTEGER NOT NULL)
PRIMARY KEY (Name, employee_SIN)
--* IDENTIFYING_REL : dependents_of
--* ROLE : dependent (1, 1)
FOREIGN KEY (employee_SIN)
    REFERENCES EMPLOYEE --* ROLE : employee (0, n)

CREATE TABLE works_on (
    Hours INTEGER,
    worker_SIN INTEGER NOT NULL,
    project_Name CHARACTER (40) NOT NULL)
PRIMARY KEY (worker_SIN, project_Name)
FOREIGN KEY (worker_SIN)
    REFERENCES EMPLOYEE --* ROLE : worker (1, n)
FOREIGN KEY (project_Name)
    REFERENCES PROJECT --* ROLE : project (1, n)

CREATE TABLE supply (
    Quantity INTEGER,
    project_Name CHARACTER (40) NOT NULL,
    supplier_Name CHARACTER (40) NOT NULL,
    part_Number INTEGER NOT NULL)
PRIMARY KEY (project_Name, supplier_Name, part_Number)
FOREIGN KEY (project_Name)
    REFERENCES PROJECT --* ROLE : project (1, n)
FOREIGN KEY (supplier_Name)
    REFERENCES SUPPLIER --* ROLE : supplier (1, n)
FOREIGN KEY (part_Number)
    REFERENCES PART --* ROLE : part (1, n)

CREATE TABLE DEPARTMENT_Locations (
    DEPARTMENT_Number INTEGER NOT NULL,
    Locations CHARACTER (40))
PRIMARY KEY (DEPARTMENT_Number, Locations)
FOREIGN KEY (DEPARTMENT_Number)
    REFERENCES DEPARTMENT

CREATE TABLE PROJECT_Locations (
    PROJECT_Name CHARACTER (40) NOT NULL,
    Building CHARACTER (40),
    Room CHARACTER (10))
PRIMARY KEY (PROJECT_Name, Building, Room)
FOREIGN KEY (PROJECT_Name)
    REFERENCES PROJECT


