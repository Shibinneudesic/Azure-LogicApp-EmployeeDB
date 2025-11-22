<?xml version="1.0" encoding="UTF-8"?> 
<xsl:stylesheet 
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ns0="http://EmployeeCSV.Schema"
    exclude-result-prefixes="ns0">

  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <!-- Match the real root: <Employees xmlns="http://EmployeeCSV.Schema"> -->
  <xsl:template match="/ns0:Employees">
    <Employees>
      <!-- Process Employee rows (they may or may not have namespace) -->
      <xsl:apply-templates select="ns0:Employee | Employee"/>
    </Employees>
  </xsl:template>


  <!-- Employee Template -->
  <xsl:template match="ns0:Employee | Employee">
    <Employee>
      <EmployeeId>
        <xsl:value-of select="EMPLOYEE_ID"/>
      </EmployeeId>

      <PersonalInfo>
        <FirstName><xsl:value-of select="FIRST_NAME"/></FirstName>
        <LastName><xsl:value-of select="LAST_NAME"/></LastName>
        <FullName>
          <xsl:value-of select="concat(FIRST_NAME, ' ', LAST_NAME)"/>
        </FullName>
      </PersonalInfo>

      <ContactInfo>
        <Email><xsl:value-of select="EMAIL"/></Email>
        <PhoneNumber><xsl:value-of select="PHONE_NUMBER"/></PhoneNumber>
      </ContactInfo>

      <EmploymentInfo>
        <HireDate><xsl:value-of select="HIRE_DATE"/></HireDate>
        <JobId><xsl:value-of select="JOB_ID"/></JobId>
        <Salary><xsl:value-of select="SALARY"/></Salary>

        <xsl:if test="normalize-space(COMMISSION_PCT) != '-'">
          <CommissionPct>
            <xsl:value-of select="COMMISSION_PCT"/>
          </CommissionPct>
        </xsl:if>
      </EmploymentInfo>

      <OrganizationInfo>
        <xsl:if test="normalize-space(MANAGER_ID) != '-'">
          <ManagerId><xsl:value-of select="MANAGER_ID"/></ManagerId>
        </xsl:if>
        <DepartmentId><xsl:value-of select="DEPARTMENT_ID"/></DepartmentId>
      </OrganizationInfo>

      <Metadata>
        <Source>CSV_Import</Source>
        <Status>Active</Status>
      </Metadata>
    </Employee>
  </xsl:template>

</xsl:stylesheet>
