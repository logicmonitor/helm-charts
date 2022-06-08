package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"strings"
)

func main() {
	m, err := walkSchema("./lm-container")

	output := map[string]any{}
	dispPaths(m, "$", output)
	marshal, err := json.MarshalIndent(output, "", "  ")
	if err != nil {
		return
	}
	fmt.Println(string(marshal))

}

func walkSchema(path string) (map[string]any, error) {
	argusSchemaFile := path + "/values.schema.json"
	bytes, err := ioutil.ReadFile(argusSchemaFile)
	m := map[string]any{}
	if err == nil {
		err = json.Unmarshal(bytes, &m)
		if err != nil {
			return nil, err
		}
	}
	files, err := ioutil.ReadDir(path + "/charts")
	if err != nil {
		return m, nil
	}

	for _, f := range files {
		if f.IsDir() {
			schema, err := walkSchema(path + "/charts/" + f.Name())
			if err != nil {
			}
			m[f.Name()] = schema
		}
	}

	return m, nil
}
func dispPaths(m any, p string, output map[string]any) {
	switch d := m.(type) {
	case map[string]any:
		for k, v := range d {
			if strings.HasSuffix(p, ".global") {
				p = "$.global"
			}
			if k == "properties" {
				dispPaths(v, fmt.Sprintf("%s", p), output)
			} else {
				dispPaths(v, fmt.Sprintf("%s.%s", p, k), output)
			}
			if k == "$comment" {
				val := v.(string)
				if strings.HasPrefix(val, "ui:") && !strings.HasSuffix(val, "-ignore") {
					varNm := strings.TrimPrefix(val, "ui:")
					if e, ok := output[varNm]; ok {
						switch c := e.(type) {
						case []string:
							c = append(c, p)
							output[varNm] = c
						case string:
							var arr []string
							arr = append(arr, c)
							arr = append(arr, p)
							output[varNm] = arr
						}
					} else {
						output[varNm] = p
					}
				}
			}
		}
	case []any:
		for idx, v := range d {
			dispPaths(v, fmt.Sprintf("%s[%d]", p, idx), output)
		}
	}
}
