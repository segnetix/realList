//
//  RealListProducts.swift
//  EnList
//
//  Created by Steven Gentry on 4/14/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import Foundation

public struct RealListProducts
{
    private static let Prefix = "com.segnetix.realList."
    
    public static let FullVersion = Prefix + "FullVersion"
    
    private static let productIdentifiers: Set<ProductIdentifier> = [RealListProducts.FullVersion]
    
    public static let store = IAPHelper(productIds: RealListProducts.productIdentifiers)
}

func resourceNameForProductIdentifier(productIdentifier: String) -> String?
{
    return productIdentifier.componentsSeparatedByString(".").last
}