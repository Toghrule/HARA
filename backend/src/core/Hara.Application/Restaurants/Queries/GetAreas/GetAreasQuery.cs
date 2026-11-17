using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Restaurants.Queries.GetAreas;

/// <summary>An area of Baku and how many active restaurants are in it.</summary>
public sealed record AreaDto(string Code, int Count);

/// <summary>The areas that have at least one active restaurant, the busiest first, so the app offers only areas with something in them.</summary>
public sealed record GetAreasQuery : IRequest<IReadOnlyList<AreaDto>>;

public class GetAreasQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetAreasQuery, IReadOnlyList<AreaDto>>
{
    public async Task<IReadOnlyList<AreaDto>> Handle(GetAreasQuery request, CancellationToken cancellationToken)
    {
        var rows = await unitOfWork.Repository<Restaurant>().Query()
            .Where(r => r.IsActive && r.District != null)
            .GroupBy(r => r.District!)
            .Select(g => new { Code = g.Key, Count = g.Count() })
            .ToListAsync(cancellationToken);

        return rows
            .Where(row => Districts.IsKnown(row.Code))
            .OrderByDescending(row => row.Count)
            .ThenBy(row => row.Code, StringComparer.Ordinal)
            .Select(row => new AreaDto(row.Code, row.Count))
            .ToList();
    }
}
