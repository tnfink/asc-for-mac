/*
     This file is part of Advanced Strategic Command; http://www.asc-hq.de
     Copyright (C) 1994-2010  Martin Bickel  and  Marc Schellenberger
 
     This program is free software; you can redistribute it and/or modify
     it under the terms of the GNU General Public License as published by
     the Free Software Foundation; either version 2 of the License, or
     (at your option) any later version.
 
     This program is distributed in the hope that it will be useful,
     but WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     GNU General Public License for more details.
 
     You should have received a copy of the GNU General Public License
     along with this program; see the file COPYING. If not, write to the 
     Free Software Foundation, Inc., 59 Temple Place, Suite 330, 
     Boston, MA  02111-1307  USA
*/


#include "consumeresource.h"
#include "action-registry.h"

#include "../buildings.h"
#include "../vehicle.h"
#include "../gamemap.h"
#include "../util/messaginghub.h"

#include <cstdlib>
#include <vector>

namespace {

const char* resourceUndoLedgerKey = "asc.resourceUndoLedger";

class DrawSession {
      ResourceDrawLog* previous;
   public:
      explicit DrawSession( ResourceDrawLog* log )
      {
         previous = activeResourceDrawLog();
         setResourceDrawLog( log );
      }
      ~DrawSession()
      {
         setResourceDrawLog( previous );
      }
};

void appendNumber( ASCString& text, int value )
{
   ASCString part;
   part.format( "%d", value );
   text += part;
}

class LedgerReader {
      const char* cursor;
   public:
      bool ok;
      explicit LedgerReader( const ASCString& text ) : cursor( text.c_str() ), ok( true ) {}
      void separator()
      {
         if ( !ok )
            return;
         if ( *cursor == '|' )
            ++cursor;
         else
            ok = false;
      }
      int number()
      {
         if ( !ok )
            return 0;
         char* end = NULL;
         long value = strtol( cursor, &end, 10 );
         if ( end == cursor ) {
            ok = false;
            return 0;
         }
         cursor = end;
         return (int) value;
      }
      void comma()
      {
         if ( !ok )
            return;
         if ( *cursor == ',' )
            ++cursor;
         else
            ok = false;
      }
      char flag()
      {
         if ( !ok || ( *cursor != 'V' && *cursor != 'L' ) ) {
            ok = false;
            return 0;
         }
         char kind = *cursor;
         ++cursor;
         return kind;
      }
      bool finished() const { return ok && *cursor == 0; }
};

bool applyReverse( GameMap* map, const ResourceDrawLog::Entry& entry )
{
   int add = -entry.delta;
   switch ( entry.place ) {
      case ResourceDrawTank: {
         Vehicle* vehicle = map->getUnit( entry.a );
         if ( !vehicle )
            return false;
         vehicle->addTankResource( entry.resource, add );
         return true;
      }
      case ResourceDrawBuilding: {
         Building* building = dynamic_cast<Building*>( map->getContainer( entry.a ) );
         if ( !building )
            return false;
         building->actstorage.resource( entry.resource ) += add;
         return true;
      }
      case ResourceDrawGlobal:
         map->bi_resource[entry.a].resource( entry.resource ) += add;
         return true;
      case ResourceDrawTributeAvail:
         map->tribute.avail[entry.a][entry.b].resource( entry.resource ) += add;
         return true;
      case ResourceDrawTributePaid:
         map->tribute.paid[entry.a][entry.b].resource( entry.resource ) += add;
         return true;
      default:
         return false;
   }
}

void collectConsumes( GameAction* action, std::vector<ConsumeResource*>& out )
{
   ConsumeResource* consume = dynamic_cast<ConsumeResource*>( action );
   if ( consume )
      out.push_back( consume );
   for ( int i = 0; i < action->getChildCount(); ++i )
      collectConsumes( action->getChild( i ), out );
}

}

ConsumeResource::ConsumeResource( ContainerBase* container, const Resources& toGet )
   : ContainerAction( container ), drawLog( NULL ), drawLogValid( false )
{
   this->toGet = toGet;
}

ConsumeResource::~ConsumeResource()
{
   delete drawLog;
}

void ConsumeResource::discardDrawLog()
{
   drawLogValid = false;
   if ( drawLog )
      drawLog->entries.clear();
}
      
      
ASCString ConsumeResource::getDescription() const
{
   ASCString res = "Consume " + toGet.toString() + " resources ";
   const ContainerBase* c = getContainer();
   if ( c ) 
      res += " of  " + c->getName();
   return  res;
}
      
      
const int consumeResourceVersion = 1;
      
void ConsumeResource::readData ( tnstream& stream ) 
{
   ContainerAction::readData( stream );
   
   int version = stream.readInt();
   if ( version < 1  || version > consumeResourceVersion)
      throw tinvalidversion ( "ConsumeResource", consumeResourceVersion, version );
   
   toGet.read( stream );
   got.read( stream );
};
      
      
void ConsumeResource::writeData ( tnstream& stream ) const
{
   ContainerAction::writeData( stream );
   stream.writeInt( consumeResourceVersion );
   toGet.write( stream );
   got.write( stream );
};


GameActionID ConsumeResource::getID() const
{
   return ActionRegistry::ConsumeResource;
}

ActionResult ConsumeResource::runAction( const Context& context )
{
   if ( !drawLog )
      drawLog = new ResourceDrawLog();
   drawLog->entries.clear();
   drawLogValid = false;

   DrawSession session( drawLog );
   got = getContainer()->getResource( toGet, false, 1, context.actingPlayer->getPosition() );
   drawLogValid = true;
   return ActionResult(0);
}


ActionResult ConsumeResource::undoAction( const Context& context )
{
   if ( drawLogValid ) {
      if ( drawLog ) {
         for ( int i = (int) drawLog->entries.size() - 1; i >= 0; --i ) {
            if ( !applyReverse( getMap(), drawLog->entries[i] ) )
               return ActionResult( 23151, "undo could not find the resource source" );
         }
      }
      return ActionResult(0);
   }

   getContainer()->putResource( got, false, 1, context.actingPlayer->getPosition() );
   return ActionResult(0);
}

void archiveResourceDrawLogs( GameMap* map )
{
   std::vector<ConsumeResource*> consumes;
   const ActionContainer::Actions& actions = map->actions.getActions();
   for ( size_t i = 0; i < actions.size(); ++i )
      collectConsumes( actions[i], consumes );

   bool any = false;
   for ( size_t i = 0; i < consumes.size(); ++i )
      if ( consumes[i]->drawLogValid )
         any = true;

   if ( !any ) {
      map->properties.remove( resourceUndoLedgerKey );
      return;
   }

   ASCString text = "1|";
   appendNumber( text, (int) consumes.size() );
   text += "|";
   for ( size_t i = 0; i < consumes.size(); ++i ) {
      ConsumeResource* consume = consumes[i];
      if ( !consume->drawLogValid || !consume->drawLog ) {
         text += "L|";
         continue;
      }
      text += "V|";
      appendNumber( text, (int) consume->drawLog->entries.size() );
      text += "|";
      for ( size_t e = 0; e < consume->drawLog->entries.size(); ++e ) {
         const ResourceDrawLog::Entry& entry = consume->drawLog->entries[e];
         appendNumber( text, entry.place );
         text += ",";
         appendNumber( text, entry.a );
         text += ",";
         appendNumber( text, entry.b );
         text += ",";
         appendNumber( text, entry.resource );
         text += ",";
         appendNumber( text, entry.delta );
         text += "|";
      }
   }
   map->properties.setValue( resourceUndoLedgerKey, text );
}

void restoreResourceDrawLogs( GameMap* map )
{
   if ( !map->properties.contains( resourceUndoLedgerKey ) )
      return;

   ASCString text = map->properties.getValue( resourceUndoLedgerKey );
   if ( text.empty() )
      return;

   std::vector<ConsumeResource*> consumes;
   const ActionContainer::Actions& actions = map->actions.getActions();
   for ( size_t i = 0; i < actions.size(); ++i )
      collectConsumes( actions[i], consumes );

   LedgerReader reader( text );
   int version = reader.number();
   reader.separator();
   int count = reader.number();
   reader.separator();
   if ( !reader.ok || version != 1 || count != (int) consumes.size() ) {
      warningMessage( "resource undo ledger does not match the saved actions; falling back to the historical refund" );
      return;
   }

   for ( int i = 0; i < count && reader.ok; ++i ) {
      char kind = reader.flag();
      reader.separator();
      if ( !reader.ok )
         break;
      if ( kind == 'L' ) {
         consumes[i]->discardDrawLog();
         continue;
      }
      int entries = reader.number();
      reader.separator();
      if ( !consumes[i]->drawLog )
         consumes[i]->drawLog = new ResourceDrawLog();
      consumes[i]->drawLog->entries.clear();
      for ( int e = 0; e < entries && reader.ok; ++e ) {
         ResourceDrawLog::Entry entry;
         entry.place = reader.number();
         reader.comma();
         entry.a = reader.number();
         reader.comma();
         entry.b = reader.number();
         reader.comma();
         entry.resource = reader.number();
         reader.comma();
         entry.delta = reader.number();
         reader.separator();
         if ( reader.ok )
            consumes[i]->drawLog->entries.push_back( entry );
      }
      if ( reader.ok )
         consumes[i]->drawLogValid = true;
   }

   if ( !reader.ok || !reader.finished() ) {
      for ( size_t i = 0; i < consumes.size(); ++i )
         consumes[i]->discardDrawLog();
      warningMessage( "resource undo ledger could not be read; falling back to the historical refund" );
   }
}

ActionResult ConsumeResource::postCheck()
{
   return ActionResult(0);
}


namespace {
   const bool r1 = registerAction<ConsumeResource> ( ActionRegistry::ConsumeResource );
}
