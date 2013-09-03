<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:eaditor="https://github.com/ewg118/eaditor" exclude-result-prefixes="#all"
	version="2.0">
	<xsl:output method="xhtml" encoding="UTF-8" indent="yes"/>
	<xsl:include href="templates.xsl"/>
	<xsl:include href="functions.xsl"/>

	<xsl:variable name="flickr-api-key" select="/content/config/flickr_api_key"/>
	<xsl:variable name="facets">
		<xsl:for-each select="tokenize(/content/config/theme/facets, ',')">
			<xsl:text>&amp;facet.field=</xsl:text>
			<xsl:value-of select="."/>
		</xsl:for-each>
	</xsl:variable>
	<xsl:variable name="request-uri" select="concat('http://localhost:8080', substring-before(doc('input:request')/request/request-uri, 'results/'))"/>
	<xsl:variable name="solr-url" select="concat(/content/config/solr_published, 'select/')"/>
	<xsl:variable name="ui-theme" select="/content/config/theme/jquery_ui_theme"/>
	<xsl:variable name="display_path">../</xsl:variable>
	<xsl:variable name="pipeline">results</xsl:variable>

	<!-- URL parameters -->
	<xsl:param name="q" select="doc('input:request')/request/parameters/parameter[name='q']/value"/>
	<xsl:param name="lang" select="doc('input:request')/request/parameters/parameter[name='lang']/value"/>
	<xsl:variable name="tokenized_q" select="tokenize($q, ' AND ')"/>
	<xsl:param name="sort">
		<xsl:if test="string(doc('input:request')/request/parameters/parameter[name='sort']/value)">
			<xsl:value-of select="doc('input:request')/request/parameters/parameter[name='sort']/value"/>
		</xsl:if>
	</xsl:param>
	<xsl:param name="rows">10</xsl:param>
	<xsl:param name="start">
		<xsl:choose>
			<xsl:when test="string(doc('input:request')/request/parameters/parameter[name='start']/value)">
				<xsl:value-of select="doc('input:request')/request/parameters/parameter[name='start']/value"/>
			</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:param>

	<xsl:template match="/">
		<html>
			<head>
				<title>
					<xsl:value-of select="/content/config/title"/>
					<xsl:text>: Search Results</xsl:text>
				</title>
				<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/3.8.0/build/cssgrids/grids-min.css"/>
				<!-- EADitor styling -->
				<link rel="stylesheet" href="{$display_path}ui/css/style.css"/>
				<link rel="stylesheet" href="{$display_path}ui/css/themes/{$ui-theme}.css"/>

				<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.4/jquery.min.js"/>
				<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.23/jquery-ui.min.js"/>

				<!-- menu -->
				<script type="text/javascript" src="{$display_path}ui/javascript/ui/jquery.ui.core.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/ui/jquery.ui.widget.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/ui/jquery.ui.position.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/ui/jquery.ui.button.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/ui/jquery.ui.menu.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/ui/jquery.ui.menubar.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/menu.js"/>

				<!-- page js/style -->
				<link rel="stylesheet" href="{$display_path}ui/css/jquery.multiselect.css"/>
				<link rel="stylesheet" href="{$display_path}ui/css/jquery.fancybox-1.3.4.css"/>

				<script type="text/javascript" src="{$display_path}ui/javascript/jquery.multiselect.min.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/jquery.multiselectfilter.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/jquery.fancybox-1.3.4.min.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/jquery.livequery.js"/>


				<script type="text/javascript" src="{$display_path}ui/javascript/get_facets.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/facet_functions.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/result_map_functions.js"/>
				<!--<script type="text/javascript" src="{$display_path}ui/javascript/quick_search.js"/>-->
				<script type="text/javascript" src="{$display_path}ui/javascript/sort_results.js"/>
				<script src="http://www.openlayers.org/api/OpenLayers.js" type="text/javascript">//</script>
				<script src="http://maps.google.com/maps/api/js?v=3.2&amp;sensor=false">//</script>
				<!--<xsl:copy-of select="/content/config/google_analytics/*"/>-->


				<script type="text/javascript">
					$(document).ready(function() {
						$("#map_results").fancybox({
							onComplete: function(){
								if  ($('#resultMap').html().length == 0){								
									$('#resultMap').html('');
									initialize_map('<xsl:value-of select="$q"/>');
								}
							}
						});
						$(".thumbImage a").fancybox();
						$('.flickr-link').click(function(){
							var href = $(this).attr('href');
							$.fancybox.close();
							window.open(href, '_blank');
						});
					});
				</script>
			</head>
			<body>
				<xsl:call-template name="header"/>
				<xsl:call-template name="results"/>
				<xsl:call-template name="footer"/>
			</body>
		</html>


	</xsl:template>

	<xsl:template name="results">
		<xsl:apply-templates select="/content/response"/>
	</xsl:template>

	<xsl:template match="response">
		<div class="yui3-g">
			<div id="backgroundPopup"/>
			<div class="yui3-u-1-5">
				<div class="content">
					<xsl:if test="//result[@name='response']/@numFound &gt; 0">
						<div class="data_options">
							<h3>Data Options</h3>
							<a href="{$display_path}feed/?q=*:*">
								<img alt="Atom" title="Atom" src="{$display_path}ui/images/atom-medium.png"/>
							</a>
							<xsl:if test="count(//lst[@name='georef']/int) &gt; 0">
								<a href="{$display_path}query.kml?q={$q}">
									<img src="{$display_path}ui/images/googleearth.png" alt="KML" title="KML: Limit, 500 objects"/>
								</a>
							</xsl:if>
						</div>
						<h3>Refine Results</h3>
						<!--<xsl:call-template name="quick_search"/>-->
						<xsl:apply-templates select="descendant::lst[@name='facet_fields']"/>
					</xsl:if>
				</div>
			</div>
			<div class="yui3-u-4-5">
				<div class="content">
					<xsl:if test="count(//lst[@name='georef']/int) &gt; 0">
						<div style="display:none">
							<div id="resultMap"/>
						</div>
					</xsl:if>
					<xsl:call-template name="remove_facets"/>
					<xsl:choose>
						<xsl:when test="//result[@name='response']/@numFound &gt; 0">
							<xsl:call-template name="paging"/>
							<xsl:call-template name="sort"/>
							<xsl:apply-templates select="descendant::doc"/>
							<xsl:call-template name="paging"/>
						</xsl:when>
						<xsl:otherwise>
							<h2> No results found. <a href="{$display_path}results/?q=*:*">Start over.</a></h2>
						</xsl:otherwise>
					</xsl:choose>
					<span style="display:none" id="pipeline">
						<xsl:value-of select="$pipeline"/>
					</span>
					<select style="display:none" id="ajax-temp"/>
					<ul style="display:none" id="decades-temp"/>
				</div>
			</div>
		</div>
	</xsl:template>

	<xsl:template match="doc">
		<xsl:variable name="sort_category" select="substring-before($sort, ' ')"/>
		<xsl:variable name="regularized_sort">
			<xsl:value-of select="eaditor:normalize_fields($sort_category, $lang)"/>
		</xsl:variable>

		<div class="result_div">
			<dl class="result_info">
				<div>
					<dt>
						<b>Title</b>
					</dt>
					<dd>
						<xsl:variable name="objectUri">
							<xsl:choose>
								<xsl:when test="//config/ark[@enabled='true']">
									<xsl:value-of select="concat($display_path, 'ark:/', //config/ark/naan, '/', str[@name='id'])"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="concat($display_path, 'id/', str[@name='id'])"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<a href="{$objectUri}">
							<xsl:value-of select="str[@name='unittitle_display']"/>
						</a>
					</dd>
				</div>
				<div>
					<dt>
						<b>Date</b>
					</dt>
					<dd>
						<xsl:choose>
							<xsl:when test="string(str[@name='unitdate_display'])">
								<xsl:value-of select="str[@name='unitdate_display']"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>[Unknown]</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</dd>
				</div>
				<xsl:if test="string(str[@name='publisher_display'])">
					<div>
						<dt>
							<b>Publisher</b>
						</dt>
						<dd>
							<xsl:value-of select="str[@name='publisher_display']"/>
							<xsl:if test="str[@name='agencycode_facet']">
								<xsl:value-of select="concat(' (', str[@name='agencycode_facet'], ')')"/>
							</xsl:if>
						</dd>
					</div>
				</xsl:if>
				<xsl:if test="string(str[@name='physdesc_display'])">
					<div>
						<dt>
							<b>Physical Description</b>
						</dt>
						<dd>
							<xsl:value-of select="str[@name='physdesc_display']"/>
						</dd>
					</div>
				</xsl:if>

			</dl>
			<xsl:if test="count(arr[@name='collection_thumb']/str) &gt; 0">
				<div style="float:right">
					<xsl:apply-templates select="arr[@name='collection_thumb']/str"/>
				</div>
			</xsl:if>
		</div>
	</xsl:template>

	<xsl:template match="arr[@name='collection_thumb']/str">
		<div class="thumbImage">
			<xsl:choose>
				<xsl:when test="contains(., 'flickr.com')">
					<xsl:variable name="photo_id" select="substring-before(tokenize(., '/')[last()], '_')"/>
					<xsl:variable name="flickr_uri" select="eaditor:get_flickr_uri($photo_id)"/>
					<xsl:variable name="photo_count" select="count(ancestor::doc/arr[@name='thumb_image']/str) + count(ancestor::doc/arr[@name='collection_thumb']/str)"/>
					<xsl:variable name="title" select="ancestor::doc/str[@name='unittitle_display']"/>
					<a href="#{generate-id()}" rel="{ancestor::doc/str[@name='id']}-gallery" title="{$title}: {position()} of {$photo_count}">
						<img class="ci" src="{.}"/>
					</a>
					<xsl:if test="count(ancestor::doc/arr[@name='thumb_image']/str) &gt; 0">
						<br/>
						<xsl:value-of select="$photo_count"/> images</xsl:if>
					<div style="display:none">
						<div id="{generate-id()}">
							<span href="{$flickr_uri}" class="flickr-link">
								<img src="{ancestor::doc/arr[@name='collection_reference']/str[contains(., $photo_id)]}"/>
							</span>
						</div>
						<xsl:for-each select="ancestor::doc/arr[@name='thumb_image']/str">
							<xsl:variable name="dao_id" select="substring-before(tokenize(., '/')[last()], '_')"/>
							<xsl:variable name="flickr_uri" select="eaditor:get_flickr_uri($dao_id)"/>
							<a class="image-gallery" rel="{ancestor::doc/str[@name='id']}-gallery" href="{ancestor::doc/arr[@name='reference_image']/str[contains(., $dao_id)][1]}"
								title="{$title}: {position() + count(ancestor::doc/arr[@name='collection_thumb']/str)} of {$photo_count}">
								<img src="{.}" alt="image"/>
							</a>
						</xsl:for-each>
					</div>
				</xsl:when>
				<xsl:otherwise>
					<img src="."/>
				</xsl:otherwise>
			</xsl:choose>
		</div>
	</xsl:template>

	<xsl:template name="paging">
		<xsl:variable name="start_var">
			<xsl:choose>
				<xsl:when test="string($start)">
					<xsl:value-of select="$start"/>
				</xsl:when>
				<xsl:otherwise>0</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="numFound">
			<xsl:value-of select="//result[@name='response']/@numFound"/>
		</xsl:variable>

		<xsl:variable name="next">
			<xsl:value-of select="$start_var+$rows"/>
		</xsl:variable>

		<xsl:variable name="previous">
			<xsl:choose>
				<xsl:when test="$start_var &gt;= $rows">
					<xsl:value-of select="$start_var - $rows"/>
				</xsl:when>
				<xsl:otherwise>0</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="current" select="$start_var div $rows + 1"/>
		<xsl:variable name="total" select="ceiling($numFound div $rows)"/>

		<div class="paging_div">
			<div style="float:left;">
				<xsl:text>Displaying records </xsl:text>
				<b>
					<xsl:value-of select="$start_var + 1"/>
				</b>
				<xsl:text> to </xsl:text>
				<xsl:choose>
					<xsl:when test="$numFound &gt; ($start_var + $rows)">
						<b>
							<xsl:value-of select="$start_var + $rows"/>
						</b>
					</xsl:when>
					<xsl:otherwise>
						<b>
							<xsl:value-of select="$numFound"/>
						</b>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text> of </xsl:text>
				<b>
					<xsl:value-of select="$numFound"/>
				</b>
				<xsl:text> total results.</xsl:text>
			</div>

			<!-- paging functionality -->
			<div style="float:right;">
				<xsl:choose>
					<xsl:when test="$start_var &gt;= $rows">
						<xsl:choose>
							<xsl:when test="string($sort)">
								<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={$previous}&amp;sort={$sort}">«Previous</a>
							</xsl:when>
							<xsl:otherwise>
								<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={$previous}">«Previous</a>
							</xsl:otherwise>
						</xsl:choose>

					</xsl:when>
					<xsl:otherwise>
						<span class="pagingSep">«Previous</span>
					</xsl:otherwise>
				</xsl:choose>

				<!-- always display links to the first two pages -->
				<xsl:if test="$start_var div $rows &gt;= 3">
					<xsl:choose>
						<xsl:when test="string($sort)">
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start=0&amp;sort={$sort}">
								<xsl:text>1</xsl:text>
							</a>
						</xsl:when>
						<xsl:otherwise>
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start=0">
								<xsl:text>1</xsl:text>
							</a>
						</xsl:otherwise>
					</xsl:choose>

				</xsl:if>
				<xsl:if test="$start_var div $rows &gt;= 4">
					<xsl:choose>
						<xsl:when test="string($sort)">
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={$rows}&amp;sort={$sort}">
								<xsl:text>2</xsl:text>
							</a>
						</xsl:when>
						<xsl:otherwise>
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={$rows}">
								<xsl:text>2</xsl:text>
							</a>
						</xsl:otherwise>
					</xsl:choose>

				</xsl:if>

				<!-- display only if you are on page 6 or greater -->
				<xsl:if test="$start_var div $rows &gt;= 5">
					<span class="pagingSep">...</span>
				</xsl:if>

				<!-- always display links to the previous two pages -->
				<xsl:if test="$start_var div $rows &gt;= 2">
					<xsl:choose>
						<xsl:when test="string($sort)">
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={$start_var - ($rows * 2)}&amp;sort={$sort}">
								<xsl:value-of select="($start_var div $rows) -1"/>
							</a>
						</xsl:when>
						<xsl:otherwise>
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={$start_var - ($rows * 2)}">
								<xsl:value-of select="($start_var div $rows) -1"/>
							</a>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
				<xsl:if test="$start_var div $rows &gt;= 1">
					<xsl:choose>
						<xsl:when test="string($sort)">
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={$start_var - $rows}&amp;sort={$sort}">
								<xsl:value-of select="$start_var div $rows"/>
							</a>
						</xsl:when>
						<xsl:otherwise>
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={$start_var - $rows}">
								<xsl:value-of select="$start_var div $rows"/>
							</a>
						</xsl:otherwise>
					</xsl:choose>

				</xsl:if>

				<span class="pagingBtn">
					<b>
						<xsl:value-of select="$current"/>
					</b>
				</span>

				<!-- next two pages -->
				<xsl:if test="($start_var div $rows) + 1 &lt; $total">
					<xsl:choose>
						<xsl:when test="string($sort)">
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={$start_var + $rows}&amp;sort={$sort}">
								<xsl:value-of select="($start_var div $rows) +2"/>
							</a>
						</xsl:when>
						<xsl:otherwise>
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={$start_var + $rows}">
								<xsl:value-of select="($start_var div $rows) +2"/>
							</a>
						</xsl:otherwise>
					</xsl:choose>

				</xsl:if>
				<xsl:if test="($start_var div $rows) + 2 &lt; $total">
					<xsl:choose>
						<xsl:when test="string($sort)">
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={$start_var + ($rows * 2)}&amp;sort={$sort}">
								<xsl:value-of select="($start_var div $rows) +3"/>
							</a>
						</xsl:when>
						<xsl:otherwise>
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={$start_var + ($rows * 2)}">
								<xsl:value-of select="($start_var div $rows) +3"/>
							</a>
						</xsl:otherwise>
					</xsl:choose>

				</xsl:if>
				<xsl:if test="$start_var div $rows &lt;= $total - 6">
					<span class="pagingSep">...</span>
				</xsl:if>

				<!-- last two pages -->
				<xsl:if test="$start_var div $rows &lt;= $total - 5">
					<xsl:choose>
						<xsl:when test="string($sort)">
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={($total * $rows) - ($rows * 2)}&amp;sort={$sort}">
								<xsl:value-of select="$total - 1"/>
							</a>
						</xsl:when>
						<xsl:otherwise>
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={($total * $rows) - ($rows * 2)}">
								<xsl:value-of select="$total - 1"/>
							</a>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
				<xsl:if test="$start_var div $rows &lt;= $total - 4">
					<xsl:choose>
						<xsl:when test="string($sort)">
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={($total * $rows) - $rows}&amp;sort={$sort}">
								<xsl:value-of select="$total"/>
							</a>
						</xsl:when>
						<xsl:otherwise>
							<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={($total * $rows) - $rows}">
								<xsl:value-of select="$total"/>
							</a>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>

				<xsl:choose>
					<xsl:when test="$numFound - $start_var &gt; $rows">
						<xsl:choose>
							<xsl:when test="string($sort)">
								<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={$next}&amp;sort={$sort}">Next»</a>
							</xsl:when>
							<xsl:otherwise>
								<a class="pagingBtn" href="{$display_path}results/?q={$q}&amp;start={$next}">Next»</a>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<span class="pagingSep">Next»</span>
					</xsl:otherwise>
				</xsl:choose>
			</div>
		</div>
	</xsl:template>

	<xsl:template name="sort">
		<xsl:variable name="sort_categories_string">
			<xsl:text>agency,genreform,language,timestamp,unittitle_display,year_num</xsl:text>
		</xsl:variable>
		<xsl:variable name="sort_categories" select="tokenize(normalize-space($sort_categories_string), ',')"/>

		<div class="sort_div">
			<form class="sortForm" action="{$display_path}results/">
				<select class="sortForm_categories">
					<option>Select from list...</option>
					<xsl:for-each select="$sort_categories">
						<xsl:choose>
							<xsl:when test="contains($sort, .)">
								<option value="{.}" selected="selected">
									<xsl:value-of select="eaditor:normalize_fields(., $lang)"/>
								</option>
							</xsl:when>
							<xsl:otherwise>
								<option value="{.}">
									<xsl:value-of select="eaditor:normalize_fields(., $lang)"/>
								</option>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</select>
				<select class="sortForm_order">
					<xsl:choose>
						<xsl:when test="contains(substring-after($sort, ' '), 'asc')">
							<option value="asc" selected="selected">Ascending</option>
						</xsl:when>
						<xsl:otherwise>
							<option value="asc">Ascending</option>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="contains(substring-after($sort, ' '), 'desc')">
							<option value="desc" selected="selected">Descending</option>
						</xsl:when>
						<xsl:otherwise>
							<option value="desc">Descending</option>
						</xsl:otherwise>
					</xsl:choose>
				</select>
				<xsl:if test="string($lang)">
					<input type="hidden" name="lang" value="{$lang}"/>
				</xsl:if>
				<input type="hidden" name="q" value="{$q}"/>
				<input type="hidden" name="sort" value="" class="sort_param"/>
				<xsl:choose>
					<xsl:when test="string($sort)">
						<input id="sort_button" type="submit" value="Sort Results"/>
					</xsl:when>
					<xsl:otherwise>
						<input id="sort_button" type="submit" value="Sort Results"/>
					</xsl:otherwise>
				</xsl:choose>
			</form>
		</div>
	</xsl:template>

	<xsl:template name="quick_search">
		<h3>Keyword</h3>
		<input type="text" id="qs_text"/>
	</xsl:template>

	<xsl:template match="lst[@name='facet_fields']">
		<xsl:for-each select="lst[not(@name='georef')][descendant::int]">
			<xsl:variable name="val" select="@name"/>
			<xsl:variable name="new_query">
				<xsl:for-each select="$tokenized_q[not(contains(., $val))]">
					<xsl:value-of select="."/>
					<xsl:if test="position() != last()">
						<xsl:text> AND </xsl:text>
					</xsl:if>
				</xsl:for-each>
			</xsl:variable>
			<xsl:variable name="title">
				<xsl:value-of select="eaditor:normalize_fields(@name, $lang)"/>
			</xsl:variable>
			<xsl:variable name="select_new_query">
				<xsl:choose>
					<xsl:when test="string($new_query)">
						<xsl:value-of select="$new_query"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>*:*</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>

			<xsl:choose>
				<xsl:when test="@name='century_num'">
					<button class="ui-multiselect ui-widget ui-state-default ui-corner-all" type="button" title="Date" aria-haspopup="true" style="width: 180px;" id="{@name}_link" label="{$q}">
						<span class="ui-icon ui-icon-triangle-2-n-s"/>
						<span>Date</span>
					</button>
					<div class="ui-multiselect-menu ui-widget ui-widget-content ui-corner-all date-div" style="width: 175px;">
						<div class="ui-widget-header ui-corner-all ui-multiselect-header ui-helper-clearfix ui-multiselect-hasfilter">
							<ul class="ui-helper-reset">
								<li class="ui-multiselect-close">
									<a class="ui-multiselect-close century-close" href="#">
										<span class="ui-icon ui-icon-circle-close"/>
									</a>
								</li>
							</ul>
						</div>
						<ul class="century-multiselect-checkboxes ui-helper-reset" id="{@name}-list" style="height: 175px;">
							<xsl:for-each select="int">
								<li>
									<span class="expand_century" century="{@name}" q="{$q}">
										<img src="{$display_path}ui/images/{if (contains($q, concat(':', @name))) then 'minus' else 'plus'}.gif" alt="expand"/>
									</span>
									<xsl:choose>
										<xsl:when test="contains($q, concat(':',@name))">
											<input type="checkbox" value="{@name}" checked="checked" class="century_checkbox"/>
										</xsl:when>
										<xsl:otherwise>
											<input type="checkbox" value="{@name}" class="century_checkbox"/>
										</xsl:otherwise>
									</xsl:choose>
									<!-- output for 1800s, 1900s, etc. -->
									<xsl:value-of select="eaditor:normalize_century(@name)"/>
									<ul id="century_{@name}_list" class="decades-list" style="{if(contains($q, concat(':',@name))) then '' else 'display:none'}">
										<xsl:if test="contains($q, concat(':',@name))">
											<xsl:copy-of select="document(concat($request-uri, 'get_decades/?q=', encode-for-uri($q), '&amp;century=', @name, '&amp;pipeline=', $pipeline))//li"/>
										</xsl:if>
									</ul>
								</li>
							</xsl:for-each>
						</ul>
					</div>
				</xsl:when>
				<xsl:otherwise>
					<select id="{@name}-select" multiple="multiple" class="multiselect" size="10" title="{$title}" q="{$q}" new_query="{if (contains($q, @name)) then $select_new_query else ''}"
						style="width:180px">
						<xsl:if test="contains($q, @name)">
							<xsl:copy-of select="document(concat($request-uri, 'get_facets/?q=', encode-for-uri($q), '&amp;category=', @name, '&amp;sort=index&amp;limit=-1&amp;pipeline=', $pipeline))//option"/>
						</xsl:if>
					</select>
				</xsl:otherwise>
			</xsl:choose>
			<br/>
		</xsl:for-each>
		<input type="hidden" name="q" id="facet_form_query" value="{if (string($q)) then $q else '*:*'}"/>
		<br/>
		<div class="submit_div">
			<input type="submit" value="Refine Search" id="search_button"/>
		</div>
	</xsl:template>

	<xsl:template name="remove_facets">
		<div class="remove_facets">
			<xsl:choose>
				<xsl:when test="$q = '*:*'">
					<h1>All Terms <xsl:if test="count(//lst[@name='georef']/int) &gt; 0">
							<a href="#resultMap" id="map_results">Map Results</a>
						</xsl:if>
					</h1>
				</xsl:when>
				<xsl:otherwise>
					<h1>Filters <xsl:if test="count(//lst[@name='georef']/int) &gt; 0">
							<a href="#resultMap" id="map_results">Map Results</a>
						</xsl:if>
					</h1>
				</xsl:otherwise>
			</xsl:choose>

			<xsl:for-each select="$tokenized_q">
				<xsl:variable name="val" select="."/>
				<xsl:variable name="new_query">
					<xsl:for-each select="$tokenized_q[not($val = .)]">
						<xsl:value-of select="."/>
						<xsl:if test="position() != last()">
							<xsl:text> AND </xsl:text>
						</xsl:if>
					</xsl:for-each>
				</xsl:variable>

				<!--<xsl:value-of select="."/>-->
				<xsl:choose>
					<xsl:when test="not(. = '*:*') and not(substring(., 1, 1) = '(')">
						<xsl:variable name="field" select="substring-before(., ':')"/>
						<xsl:variable name="name">
							<xsl:choose>
								<xsl:when test="string($field)">
									<xsl:value-of select="eaditor:normalize_fields($field, $lang)"/>
								</xsl:when>
								<xsl:otherwise>Keyword</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="term">
							<xsl:choose>
								<xsl:when test="string(substring-before(., ':'))">
									<xsl:value-of select="replace(substring-after(., ':'), '&#x022;', '')"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="replace(., '&#x022;', '')"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>

						<div class="ui-widget ui-state-default ui-corner-all stacked_term">
							<span class="term">
								<b><xsl:value-of select="$name"/>: </b>
								<xsl:value-of select="if ($field = 'century_num') then eaditor:normalize_century($term) else $term"/>
							</span>
							<a class="ui-icon ui-icon-closethick remove_filter" href="{$display_path}results/?q={if (string($new_query)) then encode-for-uri($new_query) else '*:*'}">X</a>
						</div>

					</xsl:when>
					<!-- if the token contains a parenthisis, then it was probably sent from the search widget and the token must be broken down further to remove other facets -->
					<xsl:when test="substring(., 1, 1) = '('">
						<xsl:variable name="tokenized-fragments" select="tokenize(., ' OR ')"/>

						<div class="ui-widget ui-state-default ui-corner-all stacked_term">
							<span class="term">
								<xsl:for-each select="$tokenized-fragments">
									<xsl:variable name="field" select="substring-before(translate(., '()', ''), ':')"/>
									<xsl:variable name="after-colon" select="substring-after(., ':')"/>

									<xsl:variable name="value">
										<xsl:choose>
											<xsl:when test="substring($after-colon, 1, 1) = '&#x022;'">
												<xsl:analyze-string select="$after-colon" regex="&#x022;([^&#x022;]+)&#x022;">
													<xsl:matching-substring>
														<xsl:value-of select="concat('&#x022;', regex-group(1), '&#x022;')"/>
													</xsl:matching-substring>
												</xsl:analyze-string>
											</xsl:when>
											<xsl:otherwise>
												<xsl:analyze-string select="$after-colon" regex="([0-9]+)">
													<xsl:matching-substring>
														<xsl:value-of select="regex-group(1)"/>
													</xsl:matching-substring>
												</xsl:analyze-string>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>

									<xsl:variable name="q_string" select="concat($field, ':', $value)"/>

									<!--<xsl:variable name="value" select="."/>-->
									<xsl:variable name="new_multicategory">
										<xsl:for-each select="$tokenized-fragments[not(contains(.,$q_string))]">
											<xsl:variable name="other_field" select="substring-before(translate(., '()', ''), ':')"/>
											<xsl:variable name="after-colon" select="substring-after(., ':')"/>

											<xsl:variable name="other_value">
												<xsl:choose>
													<xsl:when test="substring($after-colon, 1, 1) = '&#x022;'">
														<xsl:analyze-string select="$after-colon" regex="&#x022;([^&#x022;]+)&#x022;">
															<xsl:matching-substring>
																<xsl:value-of select="concat('&#x022;', regex-group(1), '&#x022;')"/>
															</xsl:matching-substring>
														</xsl:analyze-string>
													</xsl:when>
													<xsl:otherwise>
														<xsl:analyze-string select="$after-colon" regex="([0-9]+)">
															<xsl:matching-substring>
																<xsl:value-of select="regex-group(1)"/>
															</xsl:matching-substring>
														</xsl:analyze-string>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:variable>
											<xsl:value-of select="concat($other_field, ':', $other_value)"/>
											<xsl:if test="position() != last()">
												<xsl:text> OR </xsl:text>
											</xsl:if>
										</xsl:for-each>
									</xsl:variable>
									<xsl:variable name="multicategory_query">
										<xsl:choose>
											<xsl:when test="contains($new_multicategory, ' OR ')">
												<xsl:value-of select="concat('(', $new_multicategory, ')')"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="$new_multicategory"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>

									<!-- display either the term or the regularized name for the century -->
									<b>
										<xsl:value-of select="eaditor:normalize_fields($field, $lang)"/>
										<xsl:text>: </xsl:text>
									</b>
									<xsl:value-of select="if ($field='century_num') then eaditor:normalize_century($value) else $value"/>



									<xsl:text>[</xsl:text>
									<!-- concatenate the query with the multicategory removed with the new multicategory, or if the multicategory is empty, display just the $new_query -->
									<a
										href="{$display_path}results/?q={if (string($multicategory_query) and string($new_query)) then encode-for-uri(concat($new_query, ' AND ', $multicategory_query)) else if (string($multicategory_query) and not(string($new_query))) then encode-for-uri($multicategory_query) else $new_query}"
										>X</a>
									<xsl:text>]</xsl:text>
									<xsl:if test="position() != last()">
										<xsl:text> OR </xsl:text>
									</xsl:if>
								</xsl:for-each>
							</span>
							<a class="ui-icon ui-icon-closethick remove_filter" href="{$display_path}results/?q={if (string($new_query)) then encode-for-uri($new_query) else '*:*'}">X</a>

						</div>
					</xsl:when>
					<xsl:when test="not(contains(., ':'))">
						<div class="ui-widget ui-state-default ui-corner-all stacked_term">
							<span>
								<b>Keyword: </b>
								<xsl:value-of select="."/>
							</span>
						</div>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
			<!-- remove sort term -->
			<xsl:if test="string($sort)">
				<xsl:variable name="field" select="substring-before($sort, ' ')"/>
				<xsl:variable name="name">
					<xsl:value-of select="eaditor:normalize_fields($field, $lang)"/>
				</xsl:variable>

				<xsl:variable name="order">
					<xsl:choose>
						<xsl:when test="substring-after($sort, ' ') = 'asc'">Acending</xsl:when>
						<xsl:when test="substring-after($sort, ' ') = 'desc'">Descending</xsl:when>
					</xsl:choose>
				</xsl:variable>
				<div class="ui-widget ui-state-default ui-corner-all stacked_term">
					<span class="term">
						<b>Sort Category: </b>
						<xsl:value-of select="$name"/>
						<xsl:text>, </xsl:text>
						<xsl:value-of select="$order"/>
					</span>

					<a class="ui-icon ui-icon-closethick remove_filter" href="{$display_path}results/?q={$q}">X</a>
				</div>
			</xsl:if>
			<xsl:if test="string($tokenized_q[2])">
				<div class="ui-widget ui-state-default ui-corner-all stacked_term">
					<span class="term" id="clear_all">
						<a href="{$display_path}results/?q=*:*">Clear All Terms</a>
					</span>
				</div>
			</xsl:if>
		</div>
	</xsl:template>
</xsl:stylesheet>
