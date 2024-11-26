using LibOnnxRuntime

base = OrtGetApiBase() |> unsafe_load
ort = (@ccall $(base.GetApi)(ORT_API_VERSION::UInt32)::Ptr{OrtApi}) |> unsafe_load

env = Ptr{OrtEnv}(0) |> Ref
status = @ccall $(ort.CreateEnv)(ORT_LOGGING_LEVEL_VERBOSE::Cint, "Test"::Cstring, env::Ptr{Ptr{OrtEnv}})::OrtStatusPtr

@info "CreateEnv" status env[]

if status != OrtStatusPtr(0)
    msg = (@ccall $(ort.GetErrorMessage)(status::OrtStatusPtr)::Cstring) |> unsafe_string
    code = @ccall $(ort.GetErrorCode)(status::OrtStatusPtr)::Cint
    println("Status: $code $msg")
end

options = Ptr{OrtSessionOptions}(0) |> Ref
status = @ccall $(ort.CreateSessionOptions)(options::Ptr{Ptr{OrtSessionOptions}})::OrtStatusPtr
@info "CreateSessionOptions" status options[]

# TBD