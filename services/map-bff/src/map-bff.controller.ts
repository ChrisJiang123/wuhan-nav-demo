import { Controller, Get, Param, Query, Res } from "@nestjs/common";

import { MapBffService } from "./map-bff.service";

@Controller()
export class MapBffController {
  constructor(private readonly mapBffService: MapBffService) {}

  @Get("route")
  getRoute(
    @Query("origin") origin?: string,
    @Query("destination") destination?: string,
    @Query("alternatives") alternatives?: string,
  ) {
    return this.mapBffService.getRoute({ origin, destination, alternatives });
  }

  @Get("search")
  search(@Query("q") q?: string, @Query("near") near?: string) {
    return this.mapBffService.search({ q, near });
  }

  @Get("tiles/:z/:x/:y")
  async getTile(@Param("z") z: string, @Param("x") x: string, @Param("y") y: string, @Res() response: any) {
    const tile = await this.mapBffService.getTile({ z, x, y });

    for (const [header, value] of Object.entries(tile.headers)) {
      response.header(header, value);
    }

    response.status(tile.status).send(Buffer.from(tile.body));
  }
}
