<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">

	<!-- URL params -->
	<xsl:param name="q" select="doc('input:request')/request/parameters/parameter[name='q']/value"/>
	<xsl:param name="century" select="doc('input:request')/request/parameters/parameter[name='century']/value"/>
	<xsl:variable name="century_int" select="number(translate($century, '&#x022;', ''))"/>
	<xsl:variable name="decades" as="element()*">
		<decades>
			<xsl:analyze-string select="$q" regex="(decade_num:&#x022;[^&#x022;]+&#x022;)">
				<xsl:matching-substring>
					<xsl:for-each select="regex-group(1)">
						<decade>
							<xsl:value-of select="substring-after(translate(., '&#x022;', ''), ':')"/>
						</decade>
					</xsl:for-each>
				</xsl:matching-substring>
			</xsl:analyze-string>
		</decades>
	</xsl:variable>
	
	<xsl:template match="/">
		<html>
			<head>
				<title/>
			</head>
			<body>
				<ul>					
					<xsl:apply-templates select="descendant::lst[@name='decade_num']"/>
				</ul>
			</body>
		</html>
	</xsl:template>
	<xsl:template match="lst[@name='decade_num']">
		<xsl:for-each select="int">			
			<xsl:choose>
				<xsl:when test="$century_int &lt; 0">
					<xsl:if test="$century_int * 100 &lt; number(@name) and ($century_int + 1) * 100 &gt;= number(@name)">
						<xsl:call-template name="generate-list"/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$century_int &gt; 0">
					<xsl:if test="$century_int * 100 &gt; number(@name) and ($century_int - 1) * 100 &lt;= number(@name)">
						<xsl:call-template name="generate-list"/>
					</xsl:if>
				</xsl:when>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="generate-list">
		<xsl:choose>
			<xsl:when test="number(@name) &lt; 0">
				<li>
					<xsl:choose>
						<xsl:when test="boolean(index-of($decades//decade, @name)) = true()">
							<input type="checkbox" value="&#x022;{@name}&#x022;" checked="checked" class="decade_checkbox"/>
						</xsl:when>
						<xsl:otherwise>
							<input type="checkbox" value="&#x022;{@name}&#x022;" class="decade_checkbox"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:value-of select="concat(if(@name = '0') then '00' else @name, 's')"/>
				</li>
			</xsl:when>
			<xsl:otherwise>
				<li>
					<xsl:choose>
						<xsl:when test="boolean(index-of($decades//decade, @name)) = true()">
							<input type="checkbox" value="&#x022;{@name}&#x022;" checked="checked" class="decade_checkbox"/>
						</xsl:when>
						<xsl:otherwise>
							<input type="checkbox" value="&#x022;{@name}&#x022;" class="decade_checkbox"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:value-of select="concat(if(@name = '0') then '00' else @name, 's')"/>
				</li>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
