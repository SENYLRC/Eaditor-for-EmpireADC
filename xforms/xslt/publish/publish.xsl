<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ead="urn:isbn:1-931666-22-9" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:datetime="http://exslt.org/dates-and-times"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	exclude-result-prefixes="#all" version="2.0">

	<!-- config variables -->
	<xsl:variable name="url" select="/content/config/url"/>
	<xsl:variable name="geonames_api_key" select="/content/config/geonames_api_key"/>

	<xsl:variable name="geonames-url">
		<xsl:text>http://api.geonames.org</xsl:text>
	</xsl:variable>

	<xsl:template match="/">
		<xsl:apply-templates select="descendant::ead:ead|descendant::mods:modsCollection"/>
	</xsl:template>

	<xsl:template match="mods:modsCollection">
		<xsl:apply-templates select="mods:mods"/>
	</xsl:template>

	<xsl:template match="mods:mods">
		<add>
			<doc>
				<field name="id">
					<xsl:value-of select="mods:recordInfo/mods:recordIdentifier"/>
				</field>
				<field name="oai_id">
					<xsl:text>oai:</xsl:text>
					<xsl:value-of select="substring-before(substring-after($url, 'http://'), '/')"/>
					<xsl:text>:</xsl:text>
					<xsl:value-of select="mods:recordInfo/mods:recordIdentifier"/>
				</field>
				<field name="timestamp">
					<xsl:variable name="timestamp" select="datetime:dateTime()"/>
					<xsl:choose>
						<xsl:when test="contains($timestamp, 'Z')">
							<xsl:value-of select="$timestamp"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat($timestamp, 'Z')"/>
						</xsl:otherwise>
					</xsl:choose>
				</field>
				<field name="unittitle_display">
					<xsl:value-of select="mods:titleInfo/mods:title"/>
				</field>
				<field name="publisher_display">
					<xsl:value-of select="mods:recordInfo/mods:recordContentSource"/>
				</field>
				<field name="unitid_display">
					<xsl:value-of select="mods:identifier"/>
				</field>
				<field name="unitdate_display">
					<xsl:value-of select="mods:originInfo/mods:dateCreated"/>
				</field>
				<field name="physdesc_display">
					<xsl:if test="mods:relatedItem/mods:physicalDescription/mods:form">
						<xsl:value-of select="mods:relatedItem/mods:physicalDescription/mods:form"/>
						<xsl:text>, </xsl:text>
					</xsl:if>
					<xsl:value-of select="mods:relatedItem/mods:physicalDescription/mods:extent"/>
				</field>
				<field name="genreform_facet">
					<xsl:value-of select="normalize-space(mods:physicalDescription/mods:form)"/>
				</field>
				<xsl:if test="mods:relatedItem/mods:physicalDescription/mods:form">
					<field name="genreform_facet">
						<xsl:value-of select="normalize-space(mods:relatedItem/mods:physicalDescription/mods:form)"/>
					</field>
				</xsl:if>
				<xsl:for-each select="mods:name/mods:namePart[1]|mods:subject/mods:topic">
					<xsl:variable name="category" select="if(parent::mods:name[@type='personal']) then 'persname' else if (parent::mods:name[@type='corporate']) then 'corpname' else 'subject'"/>

					<field name="{$category}_facet">
						<xsl:value-of select="normalize-space(.)"/>
					</field>
				</xsl:for-each>
				<field name="fulltext">
					<xsl:for-each select="descendant-or-self::node()">
						<xsl:value-of select="text()"/>
						<xsl:text> </xsl:text>
					</xsl:for-each>
				</field>
			</doc>
		</add>
	</xsl:template>

	<xsl:template match="ead:ead">
		<add>
			<doc>
				<field name="id">
					<xsl:value-of select="@id"/>
				</field>
				<field name="eadid">
					<xsl:value-of select="@id"/>
				</field>
				<field name="oai_id">
					<xsl:text>oai:</xsl:text>
					<xsl:value-of select="substring-before(substring-after($url, 'http://'), '/')"/>
					<xsl:text>:</xsl:text>
					<xsl:value-of select="@id"/>
				</field>
				<xsl:if test="string(normalize-space(//ead:publicationstmt/ead:publisher))">
					<field name="publisher_display">
						<xsl:value-of select="normalize-space(//ead:publicationstmt/ead:publisher)"/>
					</field>
				</xsl:if>

				<!-- get info from archdesc/did, mostly for display -->
				<xsl:apply-templates select="//ead:archdesc/ead:did"/>

				<!-- facets -->
				<xsl:if test="string(normalize-space(//ead:eadid/@mainagencycode))">
					<field name="agencycode_facet">
						<xsl:value-of select="normalize-space(//ead:eadid/@mainagencycode)"/>
					</field>
				</xsl:if>

				<xsl:apply-templates
					select="descendant::ead:corpname | descendant::ead:famname | descendant::ead:genreform | descendant::ead:geogname | descendant::ead:langmaterial/ead:language | descendant::ead:persname | descendant::ead:subject"/>

				<!-- collection images -->
				<xsl:for-each select="descendant::ead:archdesc/ead:did/ead:daogrp">
					<field name="collection_thumb">
						<xsl:value-of select="ead:daoloc[@xlink:label='Thumbnail']/@xlink:href"/>
					</field>
					<field name="collection_reference">
						<xsl:choose>
							<!-- display Medium primarily, Small secondarily -->
							<xsl:when test="string(ead:daoloc[@xlink:label='Medium']/@xlink:href)">
								<xsl:value-of select="ead:daoloc[@xlink:label='Medium']/@xlink:href"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="ead:daoloc[@xlink:label='Small']/@xlink:href"/>
							</xsl:otherwise>
						</xsl:choose>
					</field>
				</xsl:for-each>

				<!-- subordinate images -->
				<xsl:for-each select="descendant::ead:daogrp">
					<xsl:if test="not(parent::ead:did[parent::ead:archdesc])">
						<field name="thumb_image">
							<xsl:value-of select="ead:daoloc[@xlink:label='Thumbnail']/@xlink:href"/>
						</field>
						<field name="reference_image">
							<xsl:choose>
								<!-- display Medium primarily, Small secondarily -->
								<xsl:when test="string(ead:daoloc[@xlink:label='Medium']/@xlink:href)">
									<xsl:value-of select="ead:daoloc[@xlink:label='Medium']/@xlink:href"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="ead:daoloc[@xlink:label='Small']/@xlink:href"/>
								</xsl:otherwise>
							</xsl:choose>
						</field>
					</xsl:if>
				</xsl:for-each>

				<!-- timestamp -->
				<field name="timestamp">
					<xsl:variable name="timestamp" select="datetime:dateTime()"/>
					<xsl:choose>
						<xsl:when test="contains($timestamp, 'Z')">
							<xsl:value-of select="$timestamp"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat($timestamp, 'Z')"/>
						</xsl:otherwise>
					</xsl:choose>
				</field>

				<!-- fulltext -->
				<field name="fulltext">
					<xsl:value-of select="ead:ead/@id"/>
					<xsl:text> </xsl:text>
					<xsl:for-each select="descendant-or-self::node()">
						<xsl:value-of select="text()"/>
						<xsl:text> </xsl:text>
						<xsl:if test="@normal">
							<xsl:value-of select="@normal"/>
							<xsl:text> </xsl:text>
						</xsl:if>
					</xsl:for-each>
				</field>
			</doc>
		</add>
	</xsl:template>

	<xsl:template
		match="ead:corpname | ead:famname | ead:genreform | ead:geogname | ead:language | ead:persname | ead:subject">
		<field name="{local-name()}_facet">
			<xsl:value-of select="normalize-space(.)"/>
		</field>
		<field name="{local-name()}_text">
			<xsl:value-of select="normalize-space(.)"/>
		</field>
		
		<!-- get coordinates -->
		<xsl:if test="local-name() = 'geogname' and string(@authfilenumber)">			
			<xsl:choose>
				<xsl:when test="@source='geonames'">
					<xsl:variable name="geonames_data" as="node()*">
						<xsl:copy-of select="document(concat($geonames-url, '/get?geonameId=', @authfilenumber, '&amp;username=', $geonames_api_key, '&amp;style=full'))"/>
					</xsl:variable>
					
					<field name="georef">
						<xsl:value-of select="@authfilenumber"/>
						<xsl:text>|</xsl:text>
						<xsl:value-of select="normalize-space(.)"/>
						<xsl:text>|</xsl:text>
						<xsl:value-of select="concat($geonames_data//lng, ',', $geonames_data//lat)"/>
					</field>
				</xsl:when>
				<xsl:when test="@source='pleiades'">
					<xsl:variable name="rdf" as="node()*">
						<xsl:copy-of select="document(concat('http://pleiades.stoa.org/places/', @authfilenumber, '/rdf'))"/>
					</xsl:variable>
					
					<xsl:if test="number($rdf//geo:long) and number($rdf//geo:lat)">
						<field name="georef">
							<xsl:value-of select="@authfilenumber"/>
							<xsl:text>|</xsl:text>
							<xsl:value-of select="normalize-space(.)"/>
							<xsl:text>|</xsl:text>
							<xsl:value-of select="concat($rdf//geo:long, ',', $rdf//geo:lat)"/>
						</field>
					</xsl:if>
				</xsl:when>
			</xsl:choose>			
		</xsl:if>
		
		<!-- uri -->
		<xsl:if test="string(@source) and string(@authfilenumber)">
			<xsl:variable name="resource">
				<xsl:choose>
					<xsl:when test="@source='geonames'">
						<xsl:value-of select="concat('http://www.geonames.org/', @authfilenumber)"/>					
					</xsl:when>
					<xsl:when test="@source='pleiades'">
						<xsl:value-of select="concat('http://pleiades.stoa.org/places/', @authfilenumber)"/>					
					</xsl:when>
					<xsl:when test="@source='lcsh' or @source='lcgft'">
						<xsl:value-of select="concat('http://id.loc.gov/authorities/', @authfilenumber)"/>					
					</xsl:when>				
					<xsl:when test="@source='viaf'">
						<xsl:value-of select="concat('http://viaf.org/viaf/', @authfilenumber)"/>					
					</xsl:when>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:if test="string($resource)">
				<field name="{local-name()}_uri">
					<xsl:value-of select="$resource"/>
				</field>
				<xsl:if test="@source='pleiades'">
					<field name="pleiades_uri">
						<xsl:value-of select="$resource"/>
					</field>
				</xsl:if>
			</xsl:if>
		</xsl:if>
		
	</xsl:template>

	<xsl:template match="ead:archdesc/ead:did">
		<field name="unittitle_display">
			<xsl:value-of select="normalize-space(ead:unittitle)"/>
		</field>
		<field name="unittitle_text">
			<xsl:value-of select="normalize-space(ead:unittitle)"/>
		</field>

		<xsl:if test="ead:unitdate">
			<field name="unitdate_display">
				<xsl:for-each select="ead:unitdate">
					<xsl:value-of select="."/>
					<xsl:if test="not(position()=last())">
						<xsl:text>, </xsl:text>
					</xsl:if>
				</xsl:for-each>
			</field>

			<xsl:for-each select="ead:unitdate">
				<xsl:if test="string(@normal)">
					<xsl:call-template name="get_date_hierarchy"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		<xsl:if test="string(ead:unitid)">
			<field name="unitid_display">
				<xsl:value-of select="ead:unitid"/>
			</field>
		</xsl:if>
		<xsl:if test="ead:physdesc">
			<field name="physdesc_display">
				<xsl:value-of select="ead:physdesc"/>
			</field>
		</xsl:if>
	</xsl:template>

	<xsl:template name="get_date_hierarchy">
		<xsl:variable name="years" select="tokenize(@normal, '/')"/>

		<xsl:for-each select="$years">
			<xsl:variable name="year_string" select="."/>
			<xsl:variable name="year" select="number($year_string)"/>
			<xsl:variable name="century" select="floor($year div 100)"/>
			<xsl:variable name="decade_digit" select="floor(number(substring($year_string, string-length($year_string) - 1, string-length($year_string))) div 10) * 10"/>
			<xsl:variable name="decade" select="concat($century, if($decade_digit = 0) then '00' else $decade_digit)"/>

			<field name="century_num">
				<xsl:value-of select="$century"/>
			</field>
			<field name="decade_num">
				<xsl:value-of select="$decade"/>
			</field>
			<field name="year_num">
				<xsl:value-of select="$year"/>
			</field>
		</xsl:for-each>
	</xsl:template>

</xsl:stylesheet>