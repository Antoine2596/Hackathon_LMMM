package gofuzzheaders

import (
    "errors"
    "fmt"
    "reflect"
)

type ConsumeFuzzer struct {
    data            []byte
    CommandPart     []byte
    RestOfArray     []byte
    NumberOfCalls   int
    position        int
}

func IsDivisibleBy(n int, divisibleby int) bool {
    return (n % divisibleby) == 0
}

func NewConsumer(fuzzData []byte) *ConsumeFuzzer {
    f := &ConsumeFuzzer{data: fuzzData, position: 0}
    return f
}

/*
    SplitToSeveral splits the input into 3 chunks:
    1: the first byte - Is converted to an int, and
       that int determines the number of command-line
       calls the fuzzer will make.
    2: The next n bytes where n is equal to the int from
       the first byte. These n bytes are converted to
       a corresponding command and represent which
       commands will be called.
    3: The rest of the data array should have a length
       that is divisible by the number of calls.
       This part is split up into equally large chunks,
       and each chunk is used as parameters for the
       corresponding command.
*/
func (f *ConsumeFuzzer) Split(minCalls, maxCalls int) error {
    if len(f.data)==0 {
        fmt.Println("f.data is", f.data)
        return errors.New("Could not split")
    }
    numberOfCalls := int(f.data[0])
    if numberOfCalls < minCalls || numberOfCalls > maxCalls {
        return errors.New("Bad number of calls")

    }
    if len(f.data) < numberOfCalls+numberOfCalls+1 {
        return errors.New("Length of data does not match required parameters")
    }

    // Define part 2 and 3 of the data array
    commandPart := f.data[1 : numberOfCalls+1]
    restOfArray := f.data[numberOfCalls+1:]

    // Just a small check. It is necessary
    if len(commandPart) != numberOfCalls {
        return errors.New("Length of commandPart does not match number of calls")
    }

    // Check if restOfArray is divisible by numberOfCalls
    if !IsDivisibleBy(len(restOfArray), numberOfCalls) {
        return errors.New("Length of commandPart does not match number of calls")
    }
    f.CommandPart = commandPart
    f.RestOfArray = restOfArray
    f.NumberOfCalls = numberOfCalls
    return nil
}

func (f *ConsumeFuzzer) GenerateStruct(targetStruct interface{}) error {
    //position := 0
    //fmt.Println("Byte position is ", *position)
    if f.position>=len(f.data) {
        return errors.New("Not enough bytes to proceed")
    }
    e := reflect.ValueOf(targetStruct).Elem()
    for i := 0; i < e.NumField(); i++ {
        //fmt.Println("Type: ", e.Field(i).Kind())
        if e.Field(i).Kind().String()=="struct" {
            panic("We have a struct")
        }
        //name := e.Type().Field(i).Name
        //fmt.Println("position is: ", position)
        fieldtype := e.Type().Field(i).Type.String()
        //fmt.Println(fieldtype)
        switch ft := fieldtype; ft {
        case "string":
            stringChunk, err := f.GetString()
            if err != nil {
                return err
            }
            chunk := stringChunk
            e.Field(i).SetString(chunk)
        case "bool":
            newBool, err := f.GetBool()
            if err != nil {
                return err
            }
            e.Field(i).SetBool(newBool)
        case "int":
            newInt, err := f.GetInt()

            if err != nil {
                return err
            }
            e.Field(i).SetInt(int64(newInt))
        case "[]string":
            //fmt.Println("the type is []string")
            continue
        case "[]byte":
            fmt.Println("the type is []byte")
            newBytes, err := f.GetBytes()
            if err != nil {
                return err
            }
            e.Field(i).SetBytes(newBytes)
        default:
            //fmt.Println("fieldtype was something else:", fieldtype)
            continue
        }
        //varName := e.Type().Field(i).Name
        //varType := e.Type().Field(i).Type
        //varValue := e.Field(i).Interface()
        //fmt.Printf("%v %v %v\n", varName,varType,varValue)
    }
    //fmt.Printf("After: %+v\n", i)
    return nil
}

func (f *ConsumeFuzzer) GetInt() (int, error) {
    if f.position>=len(f.data) {
        return 0, errors.New("Not enough bytes to create int")
    }
    returnInt := int(f.data[f.position])
    f.position++
    return returnInt, nil
}

func (f *ConsumeFuzzer) GetBytes() ([]byte, error) {
    if f.position>=len(f.data) {
        return nil, errors.New("Not enough bytes to create byte array")
    }
    length := int(f.data[f.position])
    if f.position+length>=len(f.data) {
        return nil, errors.New("Not enough bytes to create byte array")
    }   
    b := f.data[f.position:f.position+length]
    f.position = f.position + length
    return b, nil
}

func (f *ConsumeFuzzer) GetString() (string, error) {
    //fmt.Println("Complete string: ", string(data))
    //fmt.Println("And we are getting the string at position: ", position, "with length: ", length)
    //fmt.Println("...and that gives us ", string(data[position:position+length]))
    if f.position>=len(f.data) {
        return "nil", errors.New("Not enough bytes to create string")
    }
    length := int(f.data[f.position])
    if f.position+length>=len(f.data) {
        return "nil", errors.New("Not enough bytes to create string")
    }
    str := string(f.data[f.position:f.position+length])
    f.position = f.position + length
    return str, nil
}

func (f *ConsumeFuzzer) GetBool() (bool, error) {
    if f.position>=len(f.data) {
        return false, errors.New("Not enough bytes to create bool")
    }
    if IsDivisibleBy(int(f.data[f.position]), 2) {
        f.position++
        return true, nil
    }else{
        f.position++
        return false, nil
    }
}