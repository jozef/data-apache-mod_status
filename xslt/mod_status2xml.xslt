<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:x="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="x"
>

<xsl:output
    method="xml"
    version="1.0"
    encoding="UTF-8"

    indent="yes"
    
    
/>

<xsl:template match="/">
    <mod_status>
        <info_lines>
            <xsl:for-each select="/x:html/x:body/x:dl/x:dt">
                <line><xsl:value-of select="text()" /></line>
            </xsl:for-each>
        </info_lines>
    </mod_status>
</xsl:template>

</xsl:stylesheet>
