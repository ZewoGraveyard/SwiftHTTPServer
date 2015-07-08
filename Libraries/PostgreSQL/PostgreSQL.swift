// PostgreSQL.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

struct PostgreSQL {

    typealias PostgreSQLConnection = COpaquePointer
    typealias PostgreSQLResult = COpaquePointer

    struct PostgreSQLResultTuple {

        let fields: [(name: String, value: String)]

        subscript(name: String) -> String? {

            for field in fields {

                if name == field.name {

                    return field.value

                }

            }

            return .None

        }

    }

    let connection: PostgreSQLConnection

    init(connectionInfo: String) throws {

        self.connection = try PostgreSQL.connect(connectionInfo)
        
    }

    func finish() {

        PQfinish(connection)

    }

    func escape(input: String) -> String {

        return PostgreSQL.escape(connection, input: input)
        
    }

    func command(command: String) throws  {

        return try PostgreSQL.command(connection, command: command)

    }

    func query(query: String) throws -> PostgreSQLResult {

        return try PostgreSQL.query(connection, command: query)

    }

    func begin() throws {

        try PostgreSQL.command(connection, command: "BEGIN")

    }

    func end() throws {

        try PostgreSQL.command(connection, command: "END")

    }

    func transaction(block: Void throws -> Void) throws {
        
        try begin()
        try block()
        try end()
        
    }

    func clear(result: PostgreSQLResult) {

        PQclear(result)
        
    }

}

extension PostgreSQL {

    static func escape(connection: PostgreSQLConnection, input: String) -> String {

        let length: Int = input.utf8.count
        let CString = PQescapeLiteral(connection, input, length)
        return String.fromCString(CString)!

    }

    static func command(connection: PostgreSQLConnection, command: String) throws {

        let result = PQexec(connection, command) as PostgreSQLResult

        if PQresultStatus(result) != PGRES_COMMAND_OK {

            PQclear(result)
            throw PostgreSQL.errorForConnection(connection, description: "\"\(command)\" command failed")
            
        }

        PQclear(result)

    }

    static func query(connection: PostgreSQLConnection, command: String) throws -> PostgreSQLResult {

        let result = PQexec(connection, command) as PostgreSQLResult

        if PQresultStatus(result) != PGRES_TUPLES_OK {

            PQclear(result)
            throw PostgreSQL.errorForConnection(connection, description: "\"\(command)\" query failed")

        }

        return result
        
    }

    static func connect(connectionInfo: String) throws -> PostgreSQLConnection {

        let connection = PQconnectdb(connectionInfo) as PostgreSQLConnection

        if PQstatus(connection) != CONNECTION_OK {

            throw PostgreSQL.errorForConnection(connection, description: "Connection to database failed")

        }

        return connection

    }

    static func errorForConnection(connection: COpaquePointer, description: String) -> ErrorType {

        let errorReason = String.fromCString(PQerrorMessage(connection))!
        PQfinish(connection)
        return Error.Generic(description, errorReason)
        
    }

}

extension PostgreSQL.PostgreSQLResult {

    var tuples: [PostgreSQL.PostgreSQLResultTuple] {

        var ts: [PostgreSQL.PostgreSQLResultTuple] = []

        ts.reserveCapacity(numberOfTuples)

        for i in 0 ..< numberOfTuples  {

            var fields: [(name: String, value: String)] = []

            for j in 0 ..< numberOfFields  {

                let name = fieldNameAtColumn(j)
                let value =  valueAtRow(i, column: j)
                fields.append((name: name, value: value))

            }

            let tuple = PostgreSQL.PostgreSQLResultTuple(fields: fields)
            ts.append(tuple)

        }

        return ts

    }

    var numberOfFields: Int {

        return Int(PQnfields(self))
        
    }

    var numberOfTuples: Int {

        return Int(PQntuples(self))
        
    }

    func fieldNameAtColumn(column: Int) -> String {

        let CString = PQfname(self, Int32(column))
        return String.fromCString(CString)!

    }

    var fieldNames: [String] {

        var fields: [String] = []

        // TODO: look for places this can be used
        fields.reserveCapacity(numberOfFields)

        for i in 0 ..< numberOfFields  {

            let fieldName = fieldNameAtColumn(i)
            fields.append(fieldName)
            
        }

        return fields
        
    }

    func valueAtRow(row: Int, column: Int) -> String {

        let CString = PQgetvalue(self, Int32(row), Int32(column))
        return String.fromCString(CString)!

    }
    
}
