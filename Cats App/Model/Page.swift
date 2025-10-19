//
//  Page.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 17/10/25.
//

struct Page<T> {
    let items: [T]
    let page: Int
    let hasMore: Bool
    let dataSourceMode: DataSourceMode
}
