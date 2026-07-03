import { Module } from "@nestjs/common";

import { AppConfigService } from "./config.service";
import { MapBffController } from "./map-bff.controller";
import { MapBffService } from "./map-bff.service";

@Module({
  controllers: [MapBffController],
  providers: [AppConfigService, MapBffService],
})
export class AppModule {}
