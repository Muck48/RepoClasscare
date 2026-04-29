// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleSubmitReport } from "../../../index.ts";

serve(handleSubmitReport);
