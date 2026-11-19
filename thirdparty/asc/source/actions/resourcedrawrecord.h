/*
     This file is part of Advanced Strategic Command; http://www.asc-hq.de
     Copyright (C) 1994-2010  Martin Bickel  and  Marc Schellenberger

     This program is free software; you can redistribute it and/or modify
     it under the terms of the GNU General Public License as published by
     the Free Software Foundation; either version 2 of the License, or
     (at your option) any later version.
*/

#ifndef resourcedrawrecordH
#define resourcedrawrecordH

#include <vector>

//! Where a resource transfer inside ConsumeResource actually moved storage.
enum ResourceDrawPlace {
   ResourceDrawTank = 1,
   ResourceDrawBuilding = 2,
   ResourceDrawGlobal = 3,
   ResourceDrawTributeAvail = 4,
   ResourceDrawTributePaid = 5
};

/** In-memory list of storage changes made while one ConsumeResource runs.
    It is not part of the command stream. */
struct ResourceDrawLog {
   struct Entry {
      int place;
      int a;
      int b;
      int resource;
      int delta;
   };
   std::vector<Entry> entries;
};

inline ResourceDrawLog*& activeResourceDrawLog()
{
   static ResourceDrawLog* log = NULL;
   return log;
}

inline void setResourceDrawLog( ResourceDrawLog* log )
{
   activeResourceDrawLog() = log;
}

/** Record one applied storage delta. No-op when no consume is recording.
    delta is the change already applied (negative when storage decreased). */
inline void recordResourceDelta( int place, int a, int b, int resourceType, int delta )
{
   ResourceDrawLog* log = activeResourceDrawLog();
   if ( !log || delta == 0 )
      return;
   ResourceDrawLog::Entry entry;
   entry.place = place;
   entry.a = a;
   entry.b = b;
   entry.resource = resourceType;
   entry.delta = delta;
   log->entries.push_back( entry );
}

#endif
