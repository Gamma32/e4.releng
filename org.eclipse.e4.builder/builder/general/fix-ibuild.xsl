<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match="unit[@id='org.aspectj.weaver']">
  </xsl:template>
  
  <xsl:template match="unit[@id='org.aspectj.runtime']">
  </xsl:template>
  
  <xsl:template match="unit[@id='org.eclipse.equinox.weaving.cache']">
  </xsl:template>
  
  <xsl:template match="unit[@id='org.eclipse.equinox.weaving.cache.source']">
  </xsl:template>
  
  <xsl:template match="unit[@id='org.eclipse.equinox.weaving.aspectj']">
  </xsl:template>
  
  <xsl:template match="unit[@id='org.eclipse.equinox.weaving.aspectj.source']">
  </xsl:template>
  
  <xsl:template match="unit[@id='master-equinox-weaving.feature.group']">
  </xsl:template>
  
  <xsl:template match="unit[@id='master-equinox-weaving.feature.jar']">
  </xsl:template>
  
  <xsl:template match="required[@name='master-equinox-weaving.feature.group']">
  </xsl:template>
  
  <xsl:template match="unit[@id='org.eclipse.equinox.weaving.sdk.feature.group']">
  </xsl:template>
  
  <xsl:template match="unit[@id='master-jetty']">
  </xsl:template>
  
  <xsl:template match="unit[@id='master-jetty.feature.group']">
  </xsl:template>
  
  <xsl:template match="unit[@id='master-jetty.feature.jar']">
  </xsl:template>
  
  <xsl:template match="required[@name='master-jetty.feature.group']">
  </xsl:template>
  
  <xsl:template match="unit[@id='com.ibm.icu.base']">
  </xsl:template>
  
  <xsl:template match="unit[@id='com.ibm.icu.base.source']">
  </xsl:template>
  
  <xsl:template match="unit[@id='com.ibm.icu.base.feature.group']">
  </xsl:template>
  
  <xsl:template match="unit[@id='com.ibm.icu.base.feature.jar']">
  </xsl:template>
  
  <xsl:template match="required[@name='com.ibm.icu.base.feature.group']">
  </xsl:template>
  
  <xsl:template match="unit[@id='master-ecf']">
  </xsl:template>
  
  <xsl:template match="unit[@id='master-ecf.feature.group']">
  </xsl:template>
  
  <xsl:template match="unit[@id='master-ecf.feature.jar']">
  </xsl:template>
  
  <xsl:template match="required[@name='master-ecf.feature.group']">
  </xsl:template>
  
  <xsl:template match="unit[@id='org.eclipse.swt.tools']">
  </xsl:template>
  
  <xsl:template match="unit[@id='org.eclipse.swt.tools.category']">
  </xsl:template>
  
  <xsl:template match="required[@name='org.eclipse.swt.tools']">
  </xsl:template>
  
  <xsl:template match="unit[@id='master-equinox-weaving']">
  </xsl:template>
    
  <!-- Whenever you match any node or any attribute -->
  <xsl:template match="node()|@*">
    <!-- Copy the current node -->
    <xsl:copy>
      <!-- Including any attributes it has and any child nodes -->
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
