/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "../actions/action-registry.h"
#include "../actions/command.h"
#include "../actions/consumeresource.h"
#include "../basestrm.h"
#include "../buildings.h"
#include "../buildingtype.h"
#include "../containerbasetype.h"
#include "../gamemap.h"
#include "../mapalgorithms.h"
#include "../typen.h"
#include "../vehicletype.h"
#include "undoresourcetest.h"
#include "unittestutil.h"

#include <cstring>

namespace {

class HoldCommand : public Command {
   public:
      explicit HoldCommand( GameMap* map ) : Command( map ) {}
      ASCString getDescription() const { return "hold-for-undo-test"; }
      ASCString getCommandString() const { return "hold"; }
   protected:
      GameActionID getID() const { return ActionRegistry::ConsumeResource; }
      ActionResult go( const Context& ) { return ActionResult( 0 ); }
};

class StorageBuildingType : public BuildingType {
   public:
      StorageBuildingType() {
         entry = LocalCoordinate( 0, 0 );
         field_Exists[0][0] = true;
         asc_mode_tank = Resources( 10000, 10000, 10000 );
         bi_mode_tank = asc_mode_tank;
         name = "undo-energy-building";
         id = 593001;
      }
};

class GeneratorTestType : public VehicleType {
   public:
      GeneratorTestType() {
         setFunction( ContainerBaseType::MatterConverter );
         height = chfahrend;
         asc_mode_tank = Resources( 2000, 500, 8000 );
         bi_mode_tank = asc_mode_tank;
         name = "undo-energy-test";
         id = 593000;
      }
};

void expectEq( const char* what, int got, int want )
{
   if ( got != want ) {
      ASCString s;
      s.format( "%s: got %d, expected %d", what, got, want );
      throw TestFailure( s );
   }
}

Building* placeStorageBuilding( GameMap* game, const StorageBuildingType& typ, int player, MapCoordinate* vehicleSpot )
{
   for ( int y = 1; y < game->ysize - 1; ++y )
      for ( int x = 1; x < game->xsize - 1; ++x ) {
         MapCoordinate pos( x, y );
         MapField* fld = game->getField( pos );
         if ( !fld || fld->building || fld->vehicle )
            continue;
         for ( int d = 0; d < sidenum; ++d ) {
            MapCoordinate n = getNeighbouringFieldCoordinate( pos, d );
            MapField* next = game->getField( n );
            if ( next && !next->vehicle && !next->building ) {
               Building* built = new Building( game, pos, &typ, player, false );
               if ( vehicleSpot )
                  *vehicleSpot = n;
               return built;
            }
         }
      }
   throw TestFailure( "no empty field with a free neighbour for the storage building" );
}

void silenceOtherGenerators( GameMap* game, Vehicle* keep );

MapCoordinate findEmptyField( GameMap* game )
{
   for ( int y = 0; y < game->ysize; ++y )
      for ( int x = 0; x < game->xsize; ++x ) {
         MapField* fld = game->getField( x, y );
         if ( fld && !fld->vehicle && !fld->building )
            return MapCoordinate( x, y );
      }
   throw TestFailure( "no empty field for the generator" );
}

void placeVehicle( GameMap* game, Vehicle* veh, const MapCoordinate& pos )
{
   MapField* fld = game->getField( pos );
   fld->vehicle = veh;
   veh->setnewposition( pos );
   veh->height = chfahrend;
}

void sealOtherBuildings( GameMap* game, Building* keep )
{
   for ( int y = 0; y < game->ysize; ++y )
      for ( int x = 0; x < game->xsize; ++x ) {
         MapField* fld = game->getField( x, y );
         Building* b = fld ? fld->building : NULL;
         if ( !b || b == keep )
            continue;
         for ( int r = 0; r < 3; ++r ) {
            b->netcontrol |= (cnet_stopenergyoutput << r);
            b->netcontrol |= (cnet_stopenergyinput << r);
         }
      }
}

void openBuilding( Building* bld )
{
   for ( int r = 0; r < 3; ++r ) {
      bld->netcontrol &= ~(cnet_stopenergyoutput << r);
      bld->netcontrol &= ~(cnet_stopenergyinput << r);
   }
}

Vehicle* makeGenerator( GameMap* game, const GeneratorTestType& typ, int player )
{
   Vehicle* veh = new Vehicle( &typ, game, player );
   int fuel = veh->putResource( 8000, Resources::Fuel, false, 1, player );
   expectEq( "fuel accepted into generator", fuel, 8000 );
   int material = veh->putResource( 80, Resources::Material, false, 1, player );
   expectEq( "material accepted into generator", material, 80 );
   veh->setGeneratorStatus( true );
   expectEq( "generator is on", veh->getGeneratorStatus() ? 1 : 0, 1 );
   veh->endRound();
   expectEq( "generator energy after endRound", veh->getTank().energy, 2000 );
   int refused = veh->putResource( 50, Resources::Energy, false, 1, player );
   expectEq( "forward energy deposit still refused", refused, 0 );
   expectEq( "energy unchanged by refused deposit", veh->getTank().energy, 2000 );
   return veh;
}

void testDirectVehicleUndo( GameMap* game, const GeneratorTestType& typ )
{
   int player = game->actplayer;
   Vehicle* veh = makeGenerator( game, typ, player );
   int materialBefore = veh->getTank().material;
   int fuelBefore = veh->getTank().fuel;

   Context ctx = createTestingContext( game );
   ConsumeResource draw( veh, Resources( 833, 30, 10 ) );
   ActionResult res = draw.execute( ctx );
   if ( !res.successful() )
      throw TestFailure( "direct consume failed: " + res.getMessage() );

   expectEq( "direct draw energy", veh->getTank().energy, 1167 );
   expectEq( "direct draw material", veh->getTank().material, materialBefore - 30 );
   expectEq( "direct draw fuel", veh->getTank().fuel, fuelBefore - 10 );

   MemoryStreamStorage stored;
   {
      MemoryStream out( &stored, tnstream::writing );
      draw.write( out );
   }
   {
      MemoryStream in( &stored, tnstream::reading );
      GameAction* loaded = GameAction::readFromStream( in, game );
      if ( !loaded )
         throw TestFailure( "consume stream did not load" );
      delete loaded;
   }

   res = draw.undo( ctx );
   if ( !res.successful() )
      throw TestFailure( "direct undo failed: " + res.getMessage() );

   expectEq( "direct undo energy", veh->getTank().energy, 2000 );
   expectEq( "direct undo material", veh->getTank().material, materialBefore );
   expectEq( "direct undo fuel", veh->getTank().fuel, fuelBefore );

   res = draw.execute( ctx );
   if ( !res.successful() )
      throw TestFailure( "direct redo failed: " + res.getMessage() );
   expectEq( "direct redo energy", veh->getTank().energy, 1167 );
   expectEq( "direct redo material", veh->getTank().material, materialBefore - 30 );

   res = draw.undo( ctx );
   if ( !res.successful() )
      throw TestFailure( "second direct undo failed: " + res.getMessage() );
   expectEq( "second direct undo energy", veh->getTank().energy, 2000 );
   expectEq( "second direct undo material", veh->getTank().material, materialBefore );
   expectEq( "second direct undo fuel", veh->getTank().fuel, fuelBefore );

   MemoryStreamStorage withLedger;
   {
      MemoryStream out( &withLedger, tnstream::writing );
      draw.write( out );
   }
   draw.discardDrawLog();
   MemoryStreamStorage withoutLedger;
   {
      MemoryStream out( &withoutLedger, tnstream::writing );
      draw.write( out );
   }
   expectEq( "command stream length is independent of the ledger", withLedger.getSize(), withoutLedger.getSize() );
   if ( memcmp( withLedger.getBuffer(), withoutLedger.getBuffer(), withLedger.getSize() ) != 0 )
      throw TestFailure( "ConsumeResource stream changed when the undo ledger was dropped" );

   delete veh;
}

void testNetVehicleUndo( GameMap* game, const GeneratorTestType& typ, const StorageBuildingType& storage )
{
   int player = game->actplayer;
   if ( player < 0 || player >= 8 )
      player = 0;
   MapCoordinate spot;
   Building* bld = placeStorageBuilding( game, storage, player, &spot );
   sealOtherBuildings( game, bld );
   openBuilding( bld );
   bld->actstorage.energy = 100;
   bld->actstorage.material = 200;
   int fuelBefore = bld->actstorage.fuel;

   Vehicle* veh = makeGenerator( game, typ, player );
   placeVehicle( game, veh, spot );
   silenceOtherGenerators( game, veh );

   int energySum = bld->actstorage.energy + veh->getTank().energy;
   int materialSum = bld->actstorage.material + veh->getTank().material;
   int fuelSum = bld->actstorage.fuel + veh->getTank().fuel;

   Context ctx = createTestingContext( game );
   ctx.actingPlayer = &game->getPlayer( player );

   ConsumeResource draw( bld, Resources( 933, 40, 0 ) );
   ActionResult res = draw.execute( ctx );
   if ( !res.successful() )
      throw TestFailure( "net consume failed: " + res.getMessage() );

   expectEq( "net draw leaves generator at 1167", veh->getTank().energy, 1167 );
   expectEq( "net draw empties the building energy", bld->actstorage.energy, 0 );
   expectEq( "net draw takes material only from the building", bld->actstorage.material, 160 );
   expectEq( "net draw does not take generator material", veh->getTank().material, 80 );

   res = draw.undo( ctx );
   if ( !res.successful() )
      throw TestFailure( "net undo failed: " + res.getMessage() );

   expectEq( "net undo restores generator energy", veh->getTank().energy, 2000 );
   expectEq( "net undo restores building energy", bld->actstorage.energy, 100 );
   expectEq( "net undo restores building material", bld->actstorage.material, 200 );
   expectEq( "net undo keeps generator material", veh->getTank().material, 80 );
   expectEq( "net undo keeps building fuel", bld->actstorage.fuel, fuelBefore );
   expectEq( "energy conserved after undo", bld->actstorage.energy + veh->getTank().energy, energySum );
   expectEq( "material conserved after undo", bld->actstorage.material + veh->getTank().material, materialSum );
   expectEq( "fuel conserved after undo", bld->actstorage.fuel + veh->getTank().fuel, fuelSum );

   res = draw.execute( ctx );
   if ( !res.successful() )
      throw TestFailure( "net redo failed: " + res.getMessage() );
   expectEq( "net redo generator energy", veh->getTank().energy, 1167 );
   expectEq( "net redo building energy", bld->actstorage.energy, 0 );

   res = draw.undo( ctx );
   if ( !res.successful() )
      throw TestFailure( "second net undo failed: " + res.getMessage() );
   expectEq( "second net undo generator energy", veh->getTank().energy, 2000 );
   expectEq( "second net undo building energy", bld->actstorage.energy, 100 );
   expectEq( "second net undo building material", bld->actstorage.material, 200 );

   delete veh;
}

void testSavedLedgerUndo( GameMap* game, const GeneratorTestType& typ )
{
   int player = game->actplayer;
   if ( player < 0 || player >= 8 )
      player = 0;
   MapCoordinate spot = findEmptyField( game );
   Vehicle* veh = makeGenerator( game, typ, player );
   placeVehicle( game, veh, spot );

   Context ctx = createTestingContext( game );
   ctx.actingPlayer = &game->getPlayer( player );

   HoldCommand* hold = new HoldCommand( game );
   ActionResult res = hold->execute( ctx );
   if ( !res.successful() )
      throw TestFailure( "hold command failed: " + res.getMessage() );

   int materialFilled = veh->getTank().material;
   int fuelFilled = veh->getTank().fuel;
   Context child( ctx, hold );
   ConsumeResource* draw = new ConsumeResource( veh, Resources( 833, 30, 10 ) );
   res = draw->execute( child );
   if ( !res.successful() )
      throw TestFailure( "saved-ledger consume failed: " + res.getMessage() );
   expectEq( "saved-ledger draw energy", veh->getTank().energy, 1167 );
   expectEq( "saved-ledger draw material", veh->getTank().material, materialFilled - 30 );

   archiveResourceDrawLogs( game );
   MemoryStreamStorage properties;
   {
      MemoryStream out( &properties, tnstream::writing );
      game->properties.write( out );
   }

   MemoryStreamStorage withLedger;
   {
      MemoryStream out( &withLedger, tnstream::writing );
      draw->write( out );
   }
   draw->discardDrawLog();
   MemoryStreamStorage withoutLedger;
   {
      MemoryStream out( &withoutLedger, tnstream::writing );
      draw->write( out );
   }
   if ( withLedger.getSize() != withoutLedger.getSize()
        || memcmp( withLedger.getBuffer(), withoutLedger.getBuffer(), withLedger.getSize() ) != 0 )
      throw TestFailure( "saved consume stream changed when the undo ledger was dropped" );

   game->properties.remove( "asc.resourceUndoLedger" );
   {
      MemoryStream in( &properties, tnstream::reading );
      game->properties.read( in );
   }
   restoreResourceDrawLogs( game );

   res = game->actions.undo( ctx );
   if ( !res.successful() )
      throw TestFailure( "undo after save/load failed: " + res.getMessage() );

   expectEq( "save/load undo energy", veh->getTank().energy, 2000 );
   expectEq( "save/load undo material", veh->getTank().material, materialFilled );
   expectEq( "save/load undo fuel", veh->getTank().fuel, fuelFilled );
   delete veh;
}

void silenceOtherGenerators( GameMap* game, Vehicle* keep )
{
   for ( int p = 0; p < 8; ++p )
      for ( Player::VehicleList::iterator i = game->player[p].vehicleList.begin(); i != game->player[p].vehicleList.end(); ++i )
         if ( *i != keep )
            (*i)->setGeneratorStatus( false );
}

void testGlobalPoolUndo( GameMap* game, const GeneratorTestType& typ, const StorageBuildingType& storage )
{
   int player = game->actplayer;
   if ( player < 0 || player >= 8 )
      player = 0;
   MapCoordinate spot;
   Building* bld = placeStorageBuilding( game, storage, player, &spot );

   game->_resourcemode = 1;
   game->bi_resource[player].energy = 100;
   int materialBefore = game->bi_resource[player].material;
   int buildingEnergy = bld->actstorage.energy;

   Vehicle* veh = makeGenerator( game, typ, player );
   placeVehicle( game, veh, spot );
   silenceOtherGenerators( game, veh );
   game->cleartemps( 7 );

   Context ctx = createTestingContext( game );
   ctx.actingPlayer = &game->getPlayer( player );
   ConsumeResource draw( bld, Resources( 933, 0, 0 ) );
   ActionResult res = draw.execute( ctx );
   if ( !res.successful() )
      throw TestFailure( "global consume failed: " + res.getMessage() );

   expectEq( "global draw takes the pool first", game->bi_resource[player].energy, 0 );
   expectEq( "global draw takes the rest from the generator", veh->getTank().energy, 1167 );
   expectEq( "global draw leaves building storage alone", bld->actstorage.energy, buildingEnergy );
   expectEq( "global draw leaves pool material alone", game->bi_resource[player].material, materialBefore );

   res = draw.undo( ctx );
   if ( !res.successful() )
      throw TestFailure( "global undo failed: " + res.getMessage() );

   expectEq( "global undo restores the pool", game->bi_resource[player].energy, 100 );
   expectEq( "global undo restores the generator", veh->getTank().energy, 2000 );
   expectEq( "global undo keeps building storage", bld->actstorage.energy, buildingEnergy );
   expectEq( "global undo keeps pool material", game->bi_resource[player].material, materialBefore );
   delete veh;
}

}

void testUndoVehicleEnergy()
{
   GeneratorTestType typ;
   StorageBuildingType storage;
   auto_ptr<GameMap> game( startMap( "unittest-repair.map" ) );
   game->_resourcemode = 0;

   testDirectVehicleUndo( game.get(), typ );
   testNetVehicleUndo( game.get(), typ, storage );
   testSavedLedgerUndo( game.get(), typ );
   testGlobalPoolUndo( game.get(), typ, storage );
}
