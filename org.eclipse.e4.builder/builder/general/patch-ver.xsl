<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match="@range[../@name='org.eclipse.platform.feature.group']">
    <xsl:attribute name="range">[3.5.0,4.0.0)</xsl:attribute>
  </xsl:template>
  
  <xsl:template match="@range[../@name='org.eclipse.rcp.feature.group']">
    <xsl:attribute name="range">[3.5.0,4.0.0)</xsl:attribute>
  </xsl:template>
  
  <xsl:template match="unit[@id='org.eclipse.e4.master.categoryIU']">
    <unit id="org.eclipse.e4.swt.category" version="0.0.0">
      <properties size="2">
        <property name="org.eclipse.equinox.p2.name" value="E4 SWT"/>
        <property name="org.eclipse.equinox.p2.type.category" value="true"/>
      </properties>
      <provides size="1">
        <provided namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.swt.category" version="0.0.0"/>
      </provides>
      <requires size="2">
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.swt.as.feature.feature.group" range="0.0.0"/>
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.swt.as.source.feature.feature.group" range="0.0.0"/>
      </requires>
      <touchpoint id="null" version="0.0.0"/>
    </unit>
    <unit id="org.eclipse.e4.ui.category" version="0.0.0">
      <properties size="2">
        <property name="org.eclipse.equinox.p2.name" value="E4 UI"/>
        <property name="org.eclipse.equinox.p2.type.category" value="true"/>
      </properties>
      <provides size="1">
        <provided namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.ui.category" version="0.0.0"/>
      </provides>
      <requires size="4">
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.ui.feature.feature.group" range="0.0.0"/>
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.ui.css.feature.feature.group" range="0.0.0"/>
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.ui.source.feature.feature.group" range="0.0.0"/>
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.ui.css.source.feature.feature.group" range="0.0.0"/>
      </requires>
      <touchpoint id="null" version="0.0.0"/>
    </unit>
    <unit id="org.eclipse.e4.lang.category" version="0.0.0">
      <properties size="2">
        <property name="org.eclipse.equinox.p2.name" value="E4 Language Support"/>
        <property name="org.eclipse.equinox.p2.type.category" value="true"/>
      </properties>
      <provides size="1">
        <provided namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.lang.category" version="0.0.0"/>
      </provides>
      <requires size="2">
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.languages.feature.feature.group" range="0.0.0"/>
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.languages.source.feature.feature.group" range="0.0.0"/>
      </requires>
      <touchpoint id="null" version="0.0.0"/>
    </unit>
    <unit id="org.eclipse.e4.runtime.category" version="0.0.0">
      <properties size="2">
        <property name="org.eclipse.equinox.p2.name" value="E4 Runtime Features"/>
        <property name="org.eclipse.equinox.p2.type.category" value="true"/>
      </properties>
      <provides size="1">
        <provided namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.runtime.category" version="0.0.0"/>
      </provides>
      <requires size="1">
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.runtime.feature.feature.group" range="0.0.0"/>
      </requires>
      <touchpoint id="null" version="0.0.0"/>
    </unit>
    <unit id="org.eclipse.e4.resources.category" version="0.0.0">
      <properties size="2">
        <property name="org.eclipse.equinox.p2.name" value="E4 Resources"/>
        <property name="org.eclipse.equinox.p2.type.category" value="true"/>
      </properties>
      <provides size="1">
        <provided namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.resources.category" version="0.0.0"/>
      </provides>
      <requires size="3">
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.resources.feature.feature.group" range="0.0.0"/>
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.resources.platform.patch.source.feature.group" range="0.0.0"/>
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.resources.rcp.patch.source.feature.group" range="0.0.0"/>
      </requires>
      <touchpoint id="null" version="0.0.0"/>
    </unit>
    <unit id="org.eclipse.e4.xwt.category" version="0.0.0">
      <properties size="2">
        <property name="org.eclipse.equinox.p2.name" value="E4 XWT"/>
        <property name="org.eclipse.equinox.p2.type.category" value="true"/>
      </properties>
      <provides size="1">
        <provided namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.xwt.category" version="0.0.0"/>
      </provides>
      <requires size="4">
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.xwt.feature.feature.group" range="0.0.0"/>
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.xwt.tools.feature.feature.group" range="0.0.0"/>
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.xwt.source.feature.feature.group" range="0.0.0"/>
        <required namespace="org.eclipse.equinox.p2.iu" name="org.eclipse.e4.xwt.tools.source.feature.feature.group" range="0.0.0"/>
      </requires>
      <touchpoint id="null" version="0.0.0"/>
    </unit>
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
