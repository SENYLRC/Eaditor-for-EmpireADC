<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:nm="http://nomisma.org/id/"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:ead="urn:isbn:1-931666-22-9" xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:osgeo="http://data.ordnancesurvey.co.uk/ontology/geometry/" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:spatial="http://geovocab.org/spatial#"
	xmlns:kml="http://earth.google.com/kml/2.0" exclude-result-prefixes="#all" version="2.0">
	<xsl:include href="templates-timemap.xsl"/>

	<!-- url params -->
	<xsl:param name="id" select="doc('input:request')/request/parameters/parameter[name='id']/value"/>
	<xsl:param name="format" select="doc('input:request')/request/parameters/parameter[name='format']/value"/>
	<xsl:param name="mode" select="doc('input:request')/request/parameters/parameter[name='mode']/value"/>
	<xsl:param name="model" select="doc('input:request')/request/parameters/parameter[name='model']/value"/>

	<!-- config variables -->
	<xsl:variable name="geonames-url">http://api.geonames.org</xsl:variable>
	<xsl:variable name="geonames_api_key" select="/content/config/geonames_api_key"/>
	<xsl:variable name="url" select="/content/config/url"/>

	<xsl:variable name="rdf" as="node()*">
		<rdf:RDF>
			<xsl:if test="$model='timemap'">
				<xsl:for-each select="distinct-values(descendant::ead:geogname[contains(@source, 'pleiades')]/@authfilenumber)">
					<xsl:variable name="rdf_url" select="concat('http://pleiades.stoa.org/places/', ., '/rdf')"/>
					<xsl:copy-of select="document($rdf_url)/rdf:RDF/spatial:Feature"/>
				</xsl:for-each>
			</xsl:if>
		</rdf:RDF>
	</xsl:variable>

	<xsl:template match="/">
		<!-- determine templates to call -->
		<xsl:choose>
			<!-- timemap -->
			<xsl:when test="$model='timemap'">
				<xsl:choose>
					<xsl:when test="$format='json'">
						<xsl:call-template name="timemap"/>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<!--<xsl:when test="$model='cidoc-crm'">
				<xsl:apply-templates select="/content/eac:eac-cpf" mode="crm"/>
			</xsl:when>
			<xsl:when test="$model='snap'">
				<xsl:apply-templates select="/content/eac:eac-cpf" mode="snap"/>
			</xsl:when>-->
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
