{
  Where     https://github.com/MFernstrom/rest-api-templates
  What      Basic Auth template
  Who       Marcus Fernström
  License   Apache 2.0
  Version   1.0
}

program BasicAuthTemplate;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}cthreads,
  cmem, {$ENDIF}
  SysUtils,
  strutils,
  fphttpapp,
  httpdefs,
  httproute,
  fpjson,
  base64;

  procedure validateRequest(aRequest: TRequest);
  var
    headerValue, b64decoded, username, password: string;
  begin
    headerValue := aRequest.Authorization;

    if length(headerValue) = 0 then
      raise Exception.Create('This endpoint requires authentication');

    if ExtractWord(1, headerValue, [' ']) <> 'Basic' then
      raise Exception.Create('Only Basic Authentication is supported');

    b64decoded := DecodeStringBase64(ExtractWord(2, headerValue, [' ']));
    username := ExtractWord(1, b64decoded, [':']);
    password := ExtractWord(2, b64decoded, [':']);

    // Replace this with your own logic
    if (username <> 'marcus') or (password <> '112233') then
      raise Exception.Create('Invalid API credentials');

  end;

  procedure jsonResponse(aResponse: TResponse; JSON: TJSONObject; httpCode: integer);
  begin
    aResponse.Content := JSON.AsJSON;
    aResponse.Code := httpCode;
    aResponse.ContentType := 'application/json';
    aResponse.ContentLength := length(aResponse.Content);
    aResponse.SendContent;
  end;

  procedure apiEndpoint(aRequest: TRequest; aResponse: TResponse);
  var
    JSON: TJSONObject;
    httpCode: integer;
  begin
    JSON := TJSONObject.Create;

    try
      try
        validateRequest(aRequest);
        JSON.Add('time', DateToStr(now));
        httpCode := 200;
      except
        on E: Exception do
        begin
          JSON.Add('success', False);
          JSON.Add('reason', E.message);
          httpCode := 401;
        end;
      end;
      jsonResponse(aResponse, JSON, httpCode);

    finally
      JSON.Free;
    end;
  end;


begin
  HTTPRouter.RegisterRoute('/api', @apiEndpoint);
  Application.Port := 9080;
  Application.Threaded := True;
  Application.Initialize;
  WriteLn(format('API is ready at http://localhost:%d/', [Application.Port]));
  Application.Run;
end.
