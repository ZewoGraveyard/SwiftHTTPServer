// DatabaseResponder.swift
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

struct DatabaseResponder {

    static func get(request: HTTPRequest) throws -> HTTPResponse {

        #if os(OSX)

            let connection = PostgreSQL.Connection(database: "postgres")
            let database = try PostgreSQL(connection: connection)

            try database.transaction {

                try database.command("DECLARE myportal CURSOR FOR select * from pg_database")

                let result = try database.query("FETCH ALL in myportal")

                for fieldName in result.fieldNames  {

                    let string = String(format: "%-15s", fieldName)
                    print(string, appendNewline: false)

                }

                print("\n")

                for tuple in result.tuples {

                    for field in tuple.fields {

                        let string = String(format: "%-15s", field.value)
                        print(string, appendNewline: false)
                        
                    }
                    
                    print("")
                    
                }
                
                database.clear(result)
                
                try database.command("CLOSE myportal")
                
            }
            
            database.finish()

        #endif

        return HTTPResponse()
        
    }
    
}