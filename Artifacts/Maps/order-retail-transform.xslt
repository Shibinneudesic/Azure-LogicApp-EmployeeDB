<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" indent="yes" />

    <xsl:template match="/root">
        <Order>
            <OrderId>
                <xsl:value-of select="OrderNumber" />
            </OrderId>
            <CustomerId>
                <xsl:value-of select="CustomerID" />
            </CustomerId>
            <OrderType>
                <xsl:value-of select="OrderType" />
            </OrderType>
            <OrderStatus>Processed</OrderStatus>
            <OrderDateTime>
                <xsl:value-of select="CurrentTime" />
            </OrderDateTime>
            <Items>
                <xsl:for-each select="itemList/itemList">
                    <Item>
                        <ProductId>
                            <xsl:value-of select="ProductID" />
                        </ProductId>
                        <Quantity>
                            <xsl:value-of select="Quantity" />
                        </Quantity>
                    </Item>
                </xsl:for-each>
            </Items>
        </Order>
    </xsl:template>
</xsl:stylesheet>

