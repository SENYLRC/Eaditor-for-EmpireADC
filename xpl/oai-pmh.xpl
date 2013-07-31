<?xml version="1.0" encoding="UTF-8"?>
<!--
	Copyright (C) 2010 Ethan Gruber
	EADitor: http://code.google.com/p/eaditor/
	Apache License 2.0: http://code.google.com/p/eaditor/
	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline"
	xmlns:oxf="http://www.orbeon.com/oxf/processors">

	<p:param type="input" name="data"/>
	<p:param type="output" name="data"/>

	<p:processor name="oxf:request">
		<p:input name="config">
			<config>
				<include>/request/parameters</include>
			</config>
		</p:input>
		<p:output name="data" id="params"/>
	</p:processor>
	
	<p:processor name="oxf:request">
		<p:input name="config">
			<config>
				<include>/request/request-url</include>
			</config>
		</p:input>
		<p:output name="data" id="url"/>
	</p:processor>

	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="#data"/>
		<p:input name="params" href="#params"/>
		<p:input name="url" href="#url"/>
		<p:input name="config" href="../ui/xslt/linked_data/solr-to-oai.xsl"/>
		<p:output name="data" ref="data"/>
	</p:processor>
	

</p:config>