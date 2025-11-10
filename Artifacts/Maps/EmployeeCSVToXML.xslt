<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  
  <!-- Root template -->
  <xsl:template match="/">
    <Employees>
      <xsl:attribute name="ProcessedDate">
        <xsl:value-of select="current-dateTime()"/>
      </xsl:attribute>
      <xsl:apply-templates select="employees/employee"/>
    </Employees>
  </xsl:template>
  
  <!-- Employee template -->
  <xsl:template match="employee">
    <Employee>
      <EmployeeId>
        <xsl:value-of select="EMPLOYEE_ID"/>
      </EmployeeId>
      <PersonalInfo>
        <FirstName>
          <xsl:value-of select="FIRST_NAME"/>
        </FirstName>
        <LastName>
          <xsl:value-of select="LAST_NAME"/>
        </LastName>
        <FullName>
          <xsl:value-of select="concat(FIRST_NAME, ' ', LAST_NAME)"/>
        </FullName>
      </PersonalInfo>
      <ContactInfo>
        <xsl:if test="EMAIL">
          <Email>
            <xsl:value-of select="EMAIL"/>
          </Email>
        </xsl:if>
        <xsl:if test="PHONE_NUMBER">
          <PhoneNumber>
            <xsl:value-of select="PHONE_NUMBER"/>
          </PhoneNumber>
        </xsl:if>
      </ContactInfo>
      <EmploymentInfo>
        <xsl:if test="HIRE_DATE">
          <HireDate>
            <xsl:value-of select="HIRE_DATE"/>
          </HireDate>
        </xsl:if>
        <xsl:if test="JOB_ID">
          <JobId>
            <xsl:value-of select="JOB_ID"/>
          </JobId>
        </xsl:if>
        <xsl:if test="SALARY">
          <Salary>
            <xsl:value-of select="SALARY"/>
          </Salary>
        </xsl:if>
        <xsl:if test="COMMISSION_PCT and COMMISSION_PCT != ' - '">
          <CommissionPct>
            <xsl:value-of select="COMMISSION_PCT"/>
          </CommissionPct>
        </xsl:if>
      </EmploymentInfo>
      <OrganizationInfo>
        <xsl:if test="MANAGER_ID and MANAGER_ID != ' - '">
          <ManagerId>
            <xsl:value-of select="MANAGER_ID"/>
          </ManagerId>
        </xsl:if>
        <xsl:if test="DEPARTMENT_ID">
          <DepartmentId>
            <xsl:value-of select="DEPARTMENT_ID"/>
          </DepartmentId>
        </xsl:if>
      </OrganizationInfo>
      <Metadata>
        <Source>CSV_Import</Source>
        <ImportedAt>
          <xsl:value-of select="current-dateTime()"/>
        </ImportedAt>
        <Status>Active</Status>
      </Metadata>
    </Employee>
  </xsl:template>
  
</xsl:stylesheet>
